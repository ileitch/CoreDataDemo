#import "CrashlyticsAdapter.h"

@interface CrashlyticsAdapter ()

@property (nonatomic, strong) id<CrashlyticsAPI> crashlytics;

@end

@implementation CrashlyticsAdapter

static CrashlyticsAdapter *sharedInstance;

+ (instancetype)sharedInstance {
    return sharedInstance;
}

+ (void)with:(id<CrashlyticsAPI>)crashlytics {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[CrashlyticsAdapter alloc] initWithCrashlytics:crashlytics];
    });
}

- (instancetype)initWithCrashlytics:(id<CrashlyticsAPI>)crashlytics {
    self = [super init];
    if (self) {
        self.crashlytics = crashlytics;
    }
    return self;
}


#pragma mark - Crashlytics API Delegation

- (void)setUserIdentifier:(NSString *)identifier {
    [self.crashlytics setUserIdentifier:identifier];
}

- (void)setObjectValue:(NSObject *)value forKey:(NSString *)key {
    [self.crashlytics setObjectValue:value forKey:key];
}

- (void)recordError:(NSError *)error {
    [self.crashlytics recordError:error];
}

- (void)recordError:(NSError *)error withAdditionalUserInfo:(NSDictionary<NSString *, NSObject *> *)userInfo {
    [self.crashlytics recordError:error withAdditionalUserInfo:userInfo];
}

@end
