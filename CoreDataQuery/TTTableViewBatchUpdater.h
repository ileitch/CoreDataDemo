@import CoreData;

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "TTIndexPathTranslationDelegate.h"

@protocol TTTableViewBatchUpdaterDelegate;

@interface TTTableViewBatchUpdater : NSObject <NSFetchedResultsControllerDelegate>

typedef void (^TTTableViewBatchUpdaterCompletionBlock)(NSFetchedResultsController *, UITableView *tableView);
typedef void (^TTTableViewBatchUpdaterWillChangeRowBlock)(NSFetchedResultsController *, UITableView *tableView, NSIndexPath *indexPath);
typedef void (^TTTableViewBatchUpdaterWillMoveRowBlock)(NSFetchedResultsController *, UITableView *tableView, NSIndexPath *oldIndexPath, NSIndexPath *newIndexPath);

@property (nonatomic, weak) id<TTIndexPathTranslationDelegate>translationDelegate;
@property (nonatomic, weak) id<TTTableViewBatchUpdaterDelegate>delegate;
@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, copy) TTTableViewBatchUpdaterCompletionBlock willChangeContentBlockAfterBeginUpdates;
@property (nonatomic, copy) TTTableViewBatchUpdaterCompletionBlock didChangeContentBlockBeforeEndUpdates;
@property (nonatomic, copy) TTTableViewBatchUpdaterCompletionBlock didCompleteBatchUpdates;
@property (nonatomic, copy) TTTableViewBatchUpdaterWillChangeRowBlock willInsertRow;
@property (nonatomic, copy) TTTableViewBatchUpdaterWillChangeRowBlock willDeleteRow;
@property (nonatomic, copy) TTTableViewBatchUpdaterWillChangeRowBlock willUpdateRow;
@property (nonatomic, copy) TTTableViewBatchUpdaterWillMoveRowBlock willMoveRow;

@end

@protocol TTTableViewBatchUpdaterDelegate <NSObject>

- (void)tableViewBatchUpdater:(TTTableViewBatchUpdater *)tableViewBatchUpdater configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath withObject:(id)anObject;

@end
