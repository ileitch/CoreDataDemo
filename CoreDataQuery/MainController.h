#import <UIKit/UIKit.h>

@class TTPersistenceManager;

@interface MainController : UIViewController

@property (strong, nonatomic) TTPersistenceManager *persistenceManager;
@property (weak, nonatomic) IBOutlet UISwitch *sectionNameKeyPathToggle;

@end
