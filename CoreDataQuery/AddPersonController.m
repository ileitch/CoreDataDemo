@import SVProgressHUD;

#import "AddPersonController.h"
#import "TTPersistenceManager.h"
#import "Person.h"

@interface AddPersonController ()

@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet UITextField *sectionNameField;

@end

@implementation AddPersonController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSAssert(self.persistenceManager, @"set persistenceManager");
}

- (IBAction)saveMainQueueContext:(id)sender {
    Person *person = [NSEntityDescription insertNewObjectForEntityForName:@"Person" inManagedObjectContext:self.persistenceManager.managedObjectContext];
    person.personName = self.nameField.text;
    person.sectionName = self.sectionNameField.text;

    [self.persistenceManager saveWithPersistentSaveStrategy:TTPersistentSaveStrategyNoSave synchronously:YES];
    [SVProgressHUD showSuccessWithStatus:@"Saved"];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
    });

    [self.navigationController popToRootViewControllerAnimated:YES];
}

@end
