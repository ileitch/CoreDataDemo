@import SVProgressHUD;

#import "MainController.h"
#import "AddPersonController.h"
#import "PeopleTableViewController.h"
#import "TTPersistenceManager.h"

@implementation MainController

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    UIViewController *destinationController = segue.destinationViewController;

    if ([destinationController isKindOfClass:[AddPersonController class]]) {
        AddPersonController *add = (AddPersonController *)destinationController;
        add.persistenceManager = self.persistenceManager;
    } else if ([destinationController isKindOfClass:[PeopleTableViewController class]]) {
        PeopleTableViewController *people = (PeopleTableViewController *)destinationController;
        people.persistenceManager = self.persistenceManager;
        people.useSectionNameKeyPath = self.sectionNameKeyPathToggle.on;
    }
}

- (IBAction)savePersistentContext:(id)sender {
    [self.persistenceManager saveWithPersistentSaveStrategy:TTPersistentSaveStrategyNow synchronously:YES];

    [SVProgressHUD showSuccessWithStatus:@"Saved"];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [SVProgressHUD dismiss];
    });
}

@end
