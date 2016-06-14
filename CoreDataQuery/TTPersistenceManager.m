#import <os/trace.h>
#import "TTPersistenceManager.h"

const NSTimeInterval TTPersistenceManagerPersistentSaveInterval __attribute__((used)) = 20;

@interface TTPersistenceManager ()

@property (strong, nonatomic) dispatch_queue_t delegateQueue;
@property (assign, nonatomic) TTPersistenceType persistenceType;
@property (strong, nonatomic) NSPointerArray *delegates;
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (strong, nonatomic) NSManagedObjectContext *persistentStoreManagedObjectContext;
@property (strong, nonatomic) NSDate *persistentStoreSavedAt;
@property (strong, nonatomic, readwrite) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic, readwrite) NSManagedObjectContext *managedObjectContext;

@end


@implementation TTPersistenceManager

- (instancetype)initWithPersistenceType:(TTPersistenceType)persistenceType {
    return [self initWithPersistenceType:persistenceType storeURL:nil];
}

- (instancetype)initWithPersistenceType:(TTPersistenceType)persistenceType storeURL:(NSURL *)storeURL {
    self = [super init];
    if (self) {
        _delegateQueue = dispatch_queue_create("TTPersistenceManager.delegateQueue", DISPATCH_QUEUE_SERIAL);
        _persistenceType = persistenceType;
        _storeURL = storeURL;
        _delegates = [NSPointerArray weakObjectsPointerArray];
        _savesSynchronously = NO;
        _recoverFromFailedMigration = YES;

        NSBundle *bundle = [NSBundle mainBundle];
        _managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:@[bundle]];

        // Initialized so that we do not incur a persistent save immediately after boot.
        _persistentStoreSavedAt = [NSDate date];

        if (!_storeURL && _persistenceType == TTPersistenceTypeSQLite) {
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSURL *documentsURL = [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
            _storeURL = [documentsURL URLByAppendingPathComponent:@"DataModel.sqlite"];
        }
    }
    return self;
}

- (void)initializeCoreData {
    NSAssert(!self.persistentStoreCoordinator, @"CoreData has already been initialized");

    self.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
    NSError *error = nil;
    NSPersistentStore *store;

    if (self.persistenceType == TTPersistenceTypeSQLite) {
        store = [self addPersistentSQLiteStoreWithURL:self.storeURL error:&error];

        if (!store && self.recoverFromFailedMigration) {
            // Core Data likely failed to load the to database because the model hashes no longer
            // match those in the data model. This happens in development when a change is made
            // to the current data model (we only make new data model versions when we release,
            // doing so for every model change would be annoying).
            //
            // To workaround this, we're simply going to delete the database and try again.
            //
            // This behavior is not guarded by '#ifdef DEBUG' or similar to save us in the
            // event that we release a new app version that cannot migrate successfully.
            //
            // We will need to revisit this strategy if/when we store data locally that cannot
            // be replenished by Tophat.

            NSLog(@"Removing database '%@' in attempt to recover from error: %@", self.storeURL, error);
            [self removeDatabaseAtURL:self.storeURL];
            error = nil;
            store = [self addPersistentSQLiteStoreWithURL:self.storeURL error:&error];
        }
    } else {
        store = [self.persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:&error];
    }

    NSAssert(store != nil, @"Failed create persistent store: %@", error);

    self.persistentStoreManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    self.persistentStoreManagedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
    self.persistentStoreManagedObjectContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;

    self.managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    self.managedObjectContext.parentContext = self.persistentStoreManagedObjectContext;
    self.managedObjectContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;

    NSLog(@"Core Data initialized, main MOC: %p", self.managedObjectContext);
    os_trace("Core Data initialized, main MOC: %p", (__bridge void *)self.managedObjectContext);
}

- (void)reset {
    NSLog(@"resetting the persistence manager, main MOC: %p", self.managedObjectContext);
    os_trace("resetting the persistence manager, main MOC: %p", (__bridge void *)self.managedObjectContext);

    [self.persistentStoreManagedObjectContext performBlockAndWait:^{
        self.managedObjectContext = nil;
        self.persistentStoreManagedObjectContext = nil;

        for (NSPersistentStore *store in self.persistentStoreCoordinator.persistentStores) {
            NSError *error = nil;
            BOOL didRemoveStore = [self.persistentStoreCoordinator removePersistentStore:store error:&error];
            NSAssert(didRemoveStore, @"Failed to remove persistent store: %@", error);

            if (self.persistenceType == TTPersistenceTypeSQLite && store.URL) {
                [self removeDatabaseAtURL:store.URL];
            }
        }

        self.persistentStoreCoordinator = nil;
    }];

    [self initializeCoreData];
    [self notifyDelegates];
}

- (void)save {
    [self saveWithPersistentSaveStrategy:TTPersistentSaveStrategyIfTimeoutElapsed synchronously:self.savesSynchronously];
}

- (void)saveWithPersistentSaveStrategy:(TTPersistentSaveStrategy)strategy synchronously:(BOOL)synchronously {
    if (![self hasChangesToSave]) return;

    [self.managedObjectContext performBlockAndWait:^{
        NSError *error;

        NSAssert([self.managedObjectContext save:&error], @"Failed to save main context: %@", error);


        if (strategy == TTPersistentSaveStrategyNow) {
            [self savePersistentStoreSynchronously:synchronously];
        } else if (strategy == TTPersistentSaveStrategyIfTimeoutElapsed) {
            if (self.persistenceType == TTPersistenceTypeInMemory || fabs(self.persistentStoreSavedAt.timeIntervalSinceNow) > TTPersistenceManagerPersistentSaveInterval) {
                [self savePersistentStoreSynchronously:synchronously];
            }
        }
    }];
}

- (NSManagedObjectContext *)newChildContext {
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    context.parentContext = self.managedObjectContext;
    context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
    return context;
}

- (void)withNewChildContext:(TTPersistenceManagerContextBlock)block {
    NSManagedObjectContext *context = [self newChildContext];

    [context performBlock:^{
        if (block) block(context);

        NSError *error;

        if ([context save:&error]) {
            [self save];
        };

        if (error) {
            NSLog(@"Failed to save child context: %@", error);
        }
    }];
}

- (void)withContext:(void (^)(NSManagedObjectContext *))block {
    typeof(self) __weak _weakSelf = self;
    [self.managedObjectContext performBlockAndWait:^{
        typeof(self) __strong strongSelf = _weakSelf;
        block(strongSelf.managedObjectContext);
    }];

    [self save];
}

- (void)addDelegate:(id <TTPersistenceManagerDelegate>)delegate {
    dispatch_sync(self.delegateQueue, ^{
        [self.delegates addPointer:(__bridge void *)delegate];
    });
}

- (void)removeDelegate:(id)delegate {
    dispatch_sync(self.delegateQueue, ^{
        NSUInteger pointerIndex = NSNotFound;
        NSUInteger index = 0;

        for (id delegate_ in self.delegates) {
            if (delegate == delegate_) {
                pointerIndex = index;
                break;
            }

            index++;
        }

        if (pointerIndex != NSNotFound) {
            [self.delegates removePointerAtIndex:pointerIndex];
        }
    });
}

- (NSManagedObject *)insertObjectForEntityName:(NSString *)entityName {
    return [self insertObjectForEntityName:entityName inManagedObjectContext:self.managedObjectContext];
}

- (NSManagedObject *)insertObjectForEntityName:(NSString *)entityName inManagedObjectContext:(NSManagedObjectContext *)context {
    __block NSManagedObject *object;
    __block NSError *error;
    __block BOOL didObtainPermanentID;

    [context performBlockAndWait:^{
        object = [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:context];
        didObtainPermanentID = [context obtainPermanentIDsForObjects:@[object] error:&error];
    }];

    NSAssert(didObtainPermanentID, @"Failed to obtain permanent ID for object: %@, error: %@", object, error);

    return object;
}


#pragma mark - Properties

- (void)setSavesSynchronously:(BOOL)savesSynchronously {
#ifndef DEBUG
    FCYAssert(!savesSynchronously, @"Non-debug builds must save asynchronously.");
#endif
    _savesSynchronously = savesSynchronously;
}

- (void)setRecoverFromFailedMigration:(BOOL)recoverFromFailedMigration {
#ifndef DEBUG
    FCYAssert(recoverFromFailedMigration, @"Non-debug builds must recover from failed migration.");
#endif
    _recoverFromFailedMigration = recoverFromFailedMigration;
}


#pragma mark - Private

- (void)notifyDelegates {
    __block NSPointerArray *delegatesCopy;
    dispatch_sync(self.delegateQueue, ^{
        delegatesCopy = [self.delegates copy];
    });

    for (id <TTPersistenceManagerDelegate> delegate in delegatesCopy) {
        if (delegate) {
            [delegate persistenceManagerDidReset:self];
        } else {
            NSAssert(YES, @"A delegate of %@ did not call %@ before being deallocated.", [self class], NSStringFromSelector(@selector(removeDelegate:)));
        }
    }

    dispatch_async(self.delegateQueue, ^{
        [self.delegates compact];
    });
}

- (BOOL)hasChangesToSave {
    __block BOOL hasChangesInMainMoc = NO;
    [self.managedObjectContext performBlockAndWait:^{
        hasChangesInMainMoc = [self.managedObjectContext hasChanges];
    }];

    __block BOOL hasChangesInPersistentMoc = NO;
    [self.persistentStoreManagedObjectContext performBlockAndWait:^{
        hasChangesInPersistentMoc = [self.persistentStoreManagedObjectContext hasChanges];
    }];

    return hasChangesInMainMoc || hasChangesInPersistentMoc;
}

- (NSPersistentStore *)addPersistentSQLiteStoreWithURL:(NSURL *)url error:(NSError **)error {
    NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption: @YES,
                              NSInferMappingModelAutomaticallyOption: @YES};
    return [self.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:options error:error];
}

- (void)removeDatabaseAtURL:(NSURL *)url {
    if (!url) return;

    NSError *removeError;

    if (![[NSFileManager defaultManager] removeItemAtURL:url error:&removeError]) {
        NSLog(@"Failed to remove database '%@': %@", url, removeError);
    }
}

- (void)savePersistentStoreSynchronously:(BOOL)synchronously {
    self.persistentStoreSavedAt = [NSDate date];

    void (^persistentSave)() = ^{
        NSError *persistentError;
        NSAssert([self.persistentStoreManagedObjectContext save:&persistentError], @"Error saving persistent context: %@", persistentError);
    };
    
    if (synchronously) {
        [self.persistentStoreManagedObjectContext performBlockAndWait:persistentSave];
    } else {
        [self.persistentStoreManagedObjectContext performBlock:persistentSave];
    }
}

@end
