#import <UIKit/UIKit.h>

@class TTPersistenceManager;

@interface PeopleTableViewController : UITableViewController

@property (nonatomic, strong) TTPersistenceManager *persistenceManager;
@property (nonatomic, assign) BOOL useSectionNameKeyPath;

@end
