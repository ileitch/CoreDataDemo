#import "TTCrashlyticsLogger.h"

@implementation TTCrashlyticsLogger

- (void)log:(DDLogMessage *)logMessage formatter:(id<DDLogFormatter>)formatter {
    NSString *message = [formatter formatLogMessage:logMessage];
    [self.crashlytics tt_log:message args:nil];
}

@end
