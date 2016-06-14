#import <CocoaLumberjack/CocoaLumberjack.h>

#define TTLog(async, flg, frmt, ...) [TTLogger log:(async) flag:(flg) file:__FILE__ function:__PRETTY_FUNCTION__ line:__LINE__ format:(frmt), ##__VA_ARGS__]

#define TTLogError(frmt, ...)     TTLog(NO,                DDLogFlagError,   frmt, ##__VA_ARGS__)
#define TTLogWarn(frmt, ...)      TTLog(LOG_ASYNC_ENABLED, DDLogFlagWarning, frmt, ##__VA_ARGS__)
#define TTLogInfo(frmt, ...)      TTLog(LOG_ASYNC_ENABLED, DDLogFlagInfo,    frmt, ##__VA_ARGS__)
#define TTLogDebug(frmt, ...)     TTLog(LOG_ASYNC_ENABLED, DDLogFlagDebug,   frmt, ##__VA_ARGS__)
#define TTLogVerbose(frmt, ...)   TTLog(LOG_ASYNC_ENABLED, DDLogFlagVerbose, frmt, ##__VA_ARGS__)

@protocol TTSecondaryLogger;

@interface TTLogger : NSObject

+ (NSUInteger)logLevel;
+ (void)setLogLevel:(int)lvl;

+ (void)log:(BOOL)asynchronous
       flag:(int)flg
       file:(const char *)file
   function:(const char *)function
       line:(int)line
     format:(NSString *)format, ...;

+ (void)log:(BOOL)asynchronous
       flag:(int)flg
       file:(const char *)file
   function:(const char *)function
       line:(int)line
    message:(NSString *)message;

+ (NSString *)tailLogFiles;
+ (NSString *)currentLogFilePath;
+ (void)addSecondaryLogger:(id<TTSecondaryLogger>)secondaryLogger;

@end

@protocol TTSecondaryLogger <NSObject>

- (void)log:(DDLogMessage *)logMessage formatter:(id<DDLogFormatter>)formatter;

@end
