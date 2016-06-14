#import <Foundation/Foundation.h>
#import <StaticLibAdapters/StaticLibAdapters.h>

#import "TTLogger.h"

@interface TTCrashlyticsLogger : NSObject <TTSecondaryLogger>

@property (nonatomic, strong) id<CrashlyticsLoggable> crashlytics;

@end
