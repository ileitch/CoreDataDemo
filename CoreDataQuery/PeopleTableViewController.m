#import <Foundation/Foundation.h>
#import "AddPersonController.h"
#import "PeopleTableViewController.h"
#import "TTPersistenceManager.h"
#import "TTTableViewBatchUpdater.h"
#import "PersonCell.h"
#import "Person.h"

@interface PeopleTableViewController () <TTTableViewBatchUpdaterDelegate, TTPersistenceManagerDelegate>

@property (nonatomic, strong) TTTableViewBatchUpdater *tableViewBatchUpdater;
@property (nonatomic, strong) NSFetchedResultsController *frc;
@property (nonatomic, strong) NSFetchRequest *fetchRequest;

@end

@implementation PeopleTableViewController

- (void)dealloc {
    [self.persistenceManager removeDelegate:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.persistenceManager addDelegate:self];

    self.tableViewBatchUpdater = [[TTTableViewBatchUpdater alloc] init];
    self.tableViewBatchUpdater.delegate = self;
    self.tableViewBatchUpdater.tableView = self.tableView;

    self.fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Person"];
    NSSortDescriptor *sectionSort = [NSSortDescriptor sortDescriptorWithKey:@"sectionName" ascending:NO];
    NSSortDescriptor *nameSort = [NSSortDescriptor sortDescriptorWithKey:@"personName" ascending:NO];

    if (self.useSectionNameKeyPath) {
        self.fetchRequest.sortDescriptors = @[sectionSort, nameSort];
    } else {
        self.fetchRequest.sortDescriptors = @[nameSort];
    }

    [self setupFRC];
}

- (void)setupFRC {
    NSString *sectionNameKeyPath = nil;

    if (self.useSectionNameKeyPath) {
        sectionNameKeyPath = @"sectionName";
    }

    NSManagedObjectContext *moc = self.persistenceManager.managedObjectContext;
    self.frc = [[NSFetchedResultsController alloc] initWithFetchRequest:self.fetchRequest managedObjectContext:moc sectionNameKeyPath:sectionNameKeyPath cacheName:nil];
    self.frc.delegate = self.tableViewBatchUpdater;

    NSError *error;
    [self.frc performFetch:&error];
    NSAssert(error == nil, @"%@", error);
}

- (void)persistenceManagerDidReset:(TTPersistenceManager *)persistenceManager {
    [self setupFRC];
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.frc.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.frc.sections[section] numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PersonCell" forIndexPath:indexPath];
    id object = [self.frc objectAtIndexPath:indexPath];
    [self tableViewBatchUpdater:self.tableViewBatchUpdater configureCell:cell atIndexPath:indexPath withObject:object];
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [[[self.frc.sections[section] objects] firstObject] sectionName];
}

- (void)tableViewBatchUpdater:(TTTableViewBatchUpdater *)tableViewBatchUpdater configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath withObject:(id)anObject {
    PersonCell *personCell = (PersonCell *)cell;
    personCell.nameLabel.text = ((Person *)anObject).personName;
}

@end
