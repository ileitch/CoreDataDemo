#import "TTLogFormatter.h"

@interface TTLogFormatter ()
@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end

@implementation TTLogFormatter

- (instancetype)init {
    self = [super init];
    if (self) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        _dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
        _dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
    }
    return self;
}

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage {
    NSString *dateTimeString = [self.dateFormatter stringFromDate:logMessage.timestamp];
    NSString *flag = [self stringForFlag:logMessage.flag];
    return [NSString stringWithFormat:@"%@ %@ %@:L%lu %@ | %@", dateTimeString, flag, logMessage.fileName, (unsigned long)logMessage.line, logMessage.function, logMessage.message];
}


#pragma mark - Private

- (NSString *)stringForFlag:(DDLogFlag)flag {
    switch (flag) {
        case DDLogFlagError:
            return @"ERROR";
        case DDLogFlagWarning:
            return @"WARN";
        case DDLogFlagInfo:
            return @"INFO";
        case DDLogFlagDebug:
            return @"DEBUG";
        case DDLogFlagVerbose:
            return @"VERBOSE";
        default:
            return @"";
    }
}

@end
