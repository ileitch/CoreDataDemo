#import <Foundation/Foundation.h>

/* How To Enable CrashlyticsAdapter
 *
 * # On the App Target
 *
 * 1. Initialize Crashlytics as usual and pass the real Crashlytics instance to the adapter:
 *
 *     [Fabric with:@[[Crashlytics class]]];
 *     [CrashlyticsAdapter with:[Crashlytics sharedInstance]];
 *
 * 2. Enable logging, see CrashlyticsLoggable.h for instructions on how to enable logging
 *
 *
 * # On Libraries That Need Crashlytics
 *
 * Just use `[CrashlyticsAdapter sharedInstance]` instead of `CrashlyticsKit` or `[Crashlytics sharedInstance]`.
 *
 */

@protocol CrashlyticsAPI

- (void)setUserIdentifier:(NSString *)identifier;

- (void)setObjectValue:(NSObject *)value forKey:(NSString *)key;

- (void)recordError:(NSError *)error;
- (void)recordError:(NSError *)error withAdditionalUserInfo:(NSDictionary<NSString *, NSObject *> *)userInfo;

@end

@interface CrashlyticsAdapter : NSObject <CrashlyticsAPI>

+ (instancetype)sharedInstance;

+ (void)with:(id<CrashlyticsAPI>)crashlytics;

- (instancetype)init NS_UNAVAILABLE;

@end
