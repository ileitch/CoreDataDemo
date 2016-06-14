/*
 * To enable logging you need to add a category to CrashlyticsAdapter that implements
 * CrashlyticsLoggable in the app target. Just like this:
 *
 *     @interface CrashlyticsAdapter (Loggable) <CrashlyticsLoggable>
 *
 *     @end
 *
 *     @implementation CrashlyticsAdapter (Loggable)
 *
 *     - (void)tt_log:(NSString *)format  args:(va_list)arguments {
 *         CLSLogv(format, args)
 *     }
 *
 *     @end
 */


@protocol CrashlyticsLoggable

- (void)tt_log:(NSString *)format args:(va_list)arguments;

@end
