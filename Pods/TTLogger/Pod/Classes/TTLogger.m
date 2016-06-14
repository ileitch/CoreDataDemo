#import <CocoaLumberjack/CocoaLumberjack.h>

#import "TTLogger.h"
#import "TTLogFormatter.h"

#ifdef LOG_LEVEL_DEF
#undef LOG_LEVEL_DEF
#endif
#define LOG_LEVEL_DEF ttLogLevel

static NSUInteger ttLogLevel = DDLogLevelAll;
static DDFileLogger *fileLogger;
static NSArray *secondaryLoggers;
static TTLogFormatter *formatter;

@implementation TTLogger

+ (void)initialize {
    if (self == [TTLogger class]) {
        [self configure];
    }
}

+ (NSUInteger)logLevel {
    return ttLogLevel;
}

+ (void)setLogLevel:(int)lvl {
    ttLogLevel = lvl;
}

+ (void)addSecondaryLogger:(id<TTSecondaryLogger>)secondaryLogger {
    secondaryLoggers = [secondaryLoggers arrayByAddingObject:secondaryLogger];
}

+ (void)log:(BOOL)asynchronous
       flag:(int)flg
       file:(const char *)file
   function:(const char *)function
       line:(int)line
     format:(NSString *)format, ... {

    if (LOG_LEVEL_DEF & flg) {
        va_list ddArgs;
        va_start(ddArgs, format);
        [DDLog log:asynchronous
             level:LOG_LEVEL_DEF
              flag:flg context:0
              file:file
          function:function
              line:line
               tag:nil
            format:format
              args:ddArgs];
        va_end(ddArgs);

        DDLogMessage *logMessage;
        for (id<TTSecondaryLogger> secondaryLogger in secondaryLoggers) {
            if (!logMessage) {
                va_list secondaryArgs;
                va_start(secondaryArgs, format);
                NSString *message = [[NSString alloc] initWithFormat:format arguments:secondaryArgs];
                va_end(secondaryArgs);

                logMessage = [[DDLogMessage alloc] initWithMessage:message
                                                             level:LOG_LEVEL_DEF
                                                              flag:flg
                                                           context:0
                                                              file:[NSString stringWithFormat:@"%s", file]
                                                          function:[NSString stringWithFormat:@"%s", function]
                                                              line:line
                                                               tag:nil
                                                           options:(DDLogMessageOptions)0
                                                         timestamp:nil];
            }

            [secondaryLogger log:logMessage formatter:formatter];
        }
    }
}

+ (void)log:(BOOL)asynchronous
       flag:(int)flg
       file:(const char *)file
   function:(const char *)function
       line:(int)line
    message:(NSString *)message {
    [self log:asynchronous flag:flg file:file function:function line:line format:message];
}

+ (NSString *)tailLogFiles {
    static NSUInteger maxSize = 5000;

    NSArray *sortedLogFilePaths = [[fileLogger logFileManager] sortedLogFilePaths];

    NSMutableString *logContent = [[NSMutableString alloc] init];
    for (NSString *filePath in sortedLogFilePaths) {
        NSData *data = [[NSFileManager defaultManager] contentsAtPath:filePath];
        if ([data length] > 0) {
            NSString *content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            [logContent appendString:content];
        }

        if ([logContent length] >= maxSize) {
            break;
        }
    }

    if ([logContent length] > maxSize) {
        [logContent deleteCharactersInRange:NSMakeRange(0, [logContent length] - maxSize)];
    }

    return [logContent copy];
}

+ (NSString *)currentLogFilePath {
    return [[fileLogger currentLogFileInfo] filePath];
}


#pragma mark - Private

+ (void)configure {
    secondaryLoggers = [[NSArray alloc] init];
    formatter = [[TTLogFormatter alloc] init];

    [[DDASLLogger sharedInstance] setLogFormatter:formatter];
    [[DDTTYLogger sharedInstance] setLogFormatter:formatter];

    [DDLog addLogger:[DDASLLogger sharedInstance]];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];

    fileLogger = [[DDFileLogger alloc] init];
    fileLogger.rollingFrequency = 60 * 60 * 24; // 24 hour rolling
    fileLogger.logFileManager.maximumNumberOfLogFiles = 3;
    fileLogger.logFormatter = formatter;

    [DDLog addLogger:fileLogger];
}

@end
