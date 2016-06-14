#import <QuartzCore/QuartzCore.h>
#import "TTTableViewBatchUpdater.h"

@implementation TTTableViewBatchUpdater

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        if (self.didCompleteBatchUpdates) {
            self.didCompleteBatchUpdates(controller, self.tableView);
        }
    }];

    [self.tableView beginUpdates];

    if (self.willChangeContentBlockAfterBeginUpdates) {
        self.willChangeContentBlockAfterBeginUpdates(controller, self.tableView);
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    UITableView *tableView = self.tableView;

    if (NSFetchedResultsChangeInsert == type) {
        [tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                 withRowAnimation:UITableViewRowAnimationFade];
    } else if (NSFetchedResultsChangeDelete == type) {
        [tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                 withRowAnimation:UITableViewRowAnimationFade];
    } else {
        NSLog(@"Unhandled section change (%lu) detected in section: %lu", (unsigned long)type, (unsigned long)sectionIndex);
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    UITableView *tableView = self.tableView;
    NSIndexPath *translatedIndexPath = indexPath;
    NSIndexPath *translatedNewIndexPath = newIndexPath;

    if ([self.translationDelegate respondsToSelector:@selector(translatedIndexPathWithIndexPath:)]) {
        translatedIndexPath = [self.translationDelegate translatedIndexPathWithIndexPath:indexPath];
        translatedNewIndexPath = [self.translationDelegate translatedIndexPathWithIndexPath:newIndexPath];
    }

    switch (type) {

        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[translatedNewIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            if (self.willInsertRow) {
                self.willInsertRow(controller, self.tableView, translatedNewIndexPath);
            }

            break;

        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[translatedIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];

            if (self.willDeleteRow) {
                self.willDeleteRow(controller, self.tableView, translatedIndexPath);
            }

            break;

        case NSFetchedResultsChangeMove:
            if ([translatedIndexPath isEqual:translatedNewIndexPath]) {
                [self upateCellAtIndexPath:translatedIndexPath withObject:anObject];

                if (self.willUpdateRow) {
                    self.willUpdateRow(controller, self.tableView, translatedIndexPath);
                }
            } else {
                [tableView deleteRowsAtIndexPaths:@[translatedIndexPath] withRowAnimation:UITableViewRowAnimationFade];
                [tableView insertRowsAtIndexPaths:@[translatedNewIndexPath] withRowAnimation:UITableViewRowAnimationFade];

                if (self.willMoveRow) {
                    self.willMoveRow(controller, self.tableView, translatedIndexPath, translatedNewIndexPath);
                }
            }

            break;

        case NSFetchedResultsChangeUpdate:
            // Apple's example for NSFetchedResultsControllerDelegate uses the same approach as
            // we're using here - directly reconfiguring the cell. Various sources on the internet
            // recommend just using [UITableView reloadRowsAtIndexPaths:withRowAnimation:], however
            // this can cause the error "attempt to delete and reload the same index path" in iOS 8
            // when a cell at row 0 is updated and a cell at row 1 is moved to row 0.
            //
            // However, Apple's example does not use 'anObject', implying that whatever method
            // configures the cell needs to obtain the object from the NSFetchedResultsController.
            // This is problematic in the scenario described above, because
            // [NSFetchedResultsController objectAtIndexPath:] will already reflect the new order
            // of objects. Therefore the object now at row 0 is the object that moved from row 1,
            // yet the indexPath instance still has a row value of 0. To make things more difficult,
            // the Update event is received before the Move, denying us the chance to manually
            // correct the indexPath row.
            //
            // So this is why we're passing 'anObject' to the delegate, to avoid to need to obtain
            // the object from the NSFetchedResultsController.
            [self upateCellAtIndexPath:translatedIndexPath withObject:anObject];

            if (self.willUpdateRow) {
                self.willUpdateRow(controller, self.tableView, translatedIndexPath);
            }

            break;

        default:
            NSLog(@"Unhandled FRC Change (%lu) Detected: %@", (unsigned long)type, translatedIndexPath);
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    if (self.didChangeContentBlockBeforeEndUpdates) {
        self.didChangeContentBlockBeforeEndUpdates(controller, self.tableView);
    }

    [self.tableView endUpdates];
    [CATransaction commit];
}

- (void)upateCellAtIndexPath:(NSIndexPath *)indexPath withObject:(id)anObject {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    [self.delegate tableViewBatchUpdater:self configureCell:cell atIndexPath:indexPath withObject:anObject];
}

@end
