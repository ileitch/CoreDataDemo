@import CoreData;

FOUNDATION_EXPORT const NSTimeInterval TTPersistenceManagerPersistentSaveInterval;

typedef NS_ENUM(NSInteger, TTPersistenceType) {
    TTPersistenceTypeInMemory,
    TTPersistenceTypeSQLite
};

typedef NS_ENUM(NSInteger, TTPersistentSaveStrategy) {
    TTPersistentSaveStrategyNoSave,
    TTPersistentSaveStrategyNow,
    TTPersistentSaveStrategyIfTimeoutElapsed
};

typedef void (^TTPersistenceManagerContextBlock)(NSManagedObjectContext *context);

@protocol TTPersistenceManagerDelegate;

@interface TTPersistenceManager : NSObject

@property (strong, nonatomic, readonly) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic, readonly) NSManagedObjectContext *managedObjectContext;
@property (assign, nonatomic) BOOL savesSynchronously;
@property (assign, nonatomic) BOOL recoverFromFailedMigration;
@property (strong, nonatomic, readonly) NSURL *storeURL;

//
// Initialization
//
- (id)initWithPersistenceType:(TTPersistenceType)persistenceType;
- (id)initWithPersistenceType:(TTPersistenceType)persistenceType storeURL:(NSURL *)storeURL;
- (void)initializeCoreData;

//
// Working with managed contexts
//
- (void)withContext:(TTPersistenceManagerContextBlock)block;
- (void)withNewChildContext:(TTPersistenceManagerContextBlock)block;
- (NSManagedObjectContext *)newChildContext;
- (NSManagedObject *)insertObjectForEntityName:(NSString *)entityName;
- (NSManagedObject *)insertObjectForEntityName:(NSString *)entityName inManagedObjectContext:(NSManagedObjectContext *)context;

//
// Saving and resetting data
//

/*
 * Saves the main queue context and in background persists the data into the
 * persistent store if a predefined timeout has elapsed.
 */
- (void)save;

/*
 * Saves the main queue context and optionally saves the persistent store depending on the given
 * strategy.
 */
- (void)saveWithPersistentSaveStrategy:(TTPersistentSaveStrategy)strategy synchronously:(BOOL)synchronously;

/*
 * Removes the persistent store and resets the main queue context.
 */
- (void)reset;

//
// Manage Delegates
//
- (void)addDelegate:(id <TTPersistenceManagerDelegate>)delegate;
- (void)removeDelegate:(id <TTPersistenceManagerDelegate>)delegate;

@end

@protocol TTPersistenceManagerDelegate <NSObject>

- (void)persistenceManagerDidReset:(TTPersistenceManager *)persistenceManager;

@end
