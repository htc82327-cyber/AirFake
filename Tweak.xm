#import <UIKit/UIKit.h>
#import <CoreFoundation/CoreFoundation.h>
#import <objc/message.h>
#import <signal.h>
#import <unistd.h>

static NSString * const AFPrefsDomain = @"com.x7.airfake";
static NSString * const AFTestDarwinNotification = @"com.x7.airfake/test";
static NSString * const AFPrefsChangedDarwinNotification = @"com.x7.airfake/preferences.changed";
static NSString * const AFRespringDarwinNotification = @"com.x7.airfake/respring";

@interface SBApplication : NSObject
@property(nonatomic, readonly, retain) NSString *bundleIdentifier;
@property(nonatomic, retain) NSArray *tags;
@end

static id AFSend0(id obj, SEL sel) {
    if (!obj || !sel || ![obj respondsToSelector:sel]) return nil;
    return ((id (*)(id, SEL))objc_msgSend)(obj, sel);
}

static NSString *AFStringFromPossibleValue(id value) {
    if ([value isKindOfClass:[NSString class]]) return value;
    if ([value respondsToSelector:@selector(stringValue)]) return [value stringValue];
    return nil;
}

static id AFReadPreference(NSString *key) {
    CFPreferencesAppSynchronize((__bridge CFStringRef)AFPrefsDomain);
    CFPropertyListRef value = CFPreferencesCopyValue(
        (__bridge CFStringRef)key,
        (__bridge CFStringRef)AFPrefsDomain,
        kCFPreferencesCurrentUser,
        kCFPreferencesAnyHost
    );
    return value ? CFBridgingRelease(value) : nil;
}

static NSString *AFReadStringPreference(NSString *key, NSString *fallback) {
    id obj = AFReadPreference(key);
    if ([obj isKindOfClass:[NSString class]] && [(NSString *)obj length] > 0) return obj;
    return fallback;
}

static BOOL AFReadBoolPreference(NSString *key, BOOL fallback) {
    id obj = AFReadPreference(key);
    if ([obj respondsToSelector:@selector(boolValue)]) return [obj boolValue];
    return fallback;
}

static BOOL AFNameMatchesKeyword(NSString *name) {
    if (name.length == 0) return NO;
    NSString *keyword = AFReadStringPreference(@"Keyword", @"Soundcore");
    if (keyword.length == 0) keyword = @"Soundcore";
    return [name rangeOfString:keyword
                      options:(NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch)].location != NSNotFound;
}

@interface AFPopupController : NSObject
@property(nonatomic,strong) UIWindow *window;
@property(nonatomic,strong) UIView *card;
@property(nonatomic,strong) UILabel *titleLabel;
@property(nonatomic,strong) UILabel *subtitleLabel;
@property(nonatomic,strong) dispatch_block_t pendingHide;
+ (instancetype)shared;
- (void)showDeviceName:(NSString *)deviceName test:(BOOL)isTest;
@end

@implementation AFPopupController

+ (instancetype)shared {
    static AFPopupController *obj;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        obj = [AFPopupController new];
    });
    return obj;
}

- (UIWindow *)makeWindow {
    UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    window.windowLevel = UIWindowLevelAlert + 120.0;
    window.backgroundColor = UIColor.clearColor;
    window.userInteractionEnabled = NO;

    UIViewController *controller = [UIViewController new];
    controller.view.backgroundColor = UIColor.clearColor;
    window.rootViewController = controller;
    return window;
}

- (UIView *)buildCardIn:(UIView *)host {
    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterial];
    UIVisualEffectView *panel = [[UIVisualEffectView alloc] initWithEffect:blur];
    panel.translatesAutoresizingMaskIntoConstraints = NO;
    panel.layer.cornerRadius = 28.0;
    panel.layer.masksToBounds = YES;
    [host addSubview:panel];

    [NSLayoutConstraint activateConstraints:@[
        [panel.leadingAnchor constraintEqualToAnchor:host.leadingAnchor constant:18.0],
        [panel.trailingAnchor constraintEqualToAnchor:host.trailingAnchor constant:-18.0],
        [panel.bottomAnchor constraintEqualToAnchor:host.safeAreaLayoutGuide.bottomAnchor constant:-18.0],
        [panel.heightAnchor constraintGreaterThanOrEqualToConstant:210.0]
    ]];

    UIImageSymbolConfiguration *configuration =
        [UIImageSymbolConfiguration configurationWithPointSize:66.0
                                                        weight:UIImageSymbolWeightRegular];

    UIImageView *image = [[UIImageView alloc] initWithImage:
        [UIImage systemImageNamed:@"headphones" withConfiguration:configuration]];
    image.translatesAutoresizingMaskIntoConstraints = NO;
    image.tintColor = UIColor.labelColor;
    image.contentMode = UIViewContentModeScaleAspectFit;
    [panel.contentView addSubview:image];

    UILabel *title = [UILabel new];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    title.font = [UIFont systemFontOfSize:24.0 weight:UIFontWeightSemibold];
    title.textAlignment = NSTextAlignmentCenter;
    title.textColor = UIColor.labelColor;
    title.numberOfLines = 1;
    [panel.contentView addSubview:title];
    self.titleLabel = title;

    UILabel *subtitle = [UILabel new];
    subtitle.translatesAutoresizingMaskIntoConstraints = NO;
    subtitle.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightRegular];
    subtitle.textAlignment = NSTextAlignmentCenter;
    subtitle.textColor = UIColor.secondaryLabelColor;
    subtitle.numberOfLines = 2;
    [panel.contentView addSubview:subtitle];
    self.subtitleLabel = subtitle;

    UIView *dot = [UIView new];
    dot.translatesAutoresizingMaskIntoConstraints = NO;
    dot.backgroundColor = UIColor.systemGreenColor;
    dot.layer.cornerRadius = 5.0;
    [panel.contentView addSubview:dot];

    UILabel *status = [UILabel new];
    status.translatesAutoresizingMaskIntoConstraints = NO;
    status.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightMedium];
    status.textColor = UIColor.secondaryLabelColor;
    status.text = @"Bluetooth";
    [panel.contentView addSubview:status];

    [NSLayoutConstraint activateConstraints:@[
        [image.topAnchor constraintEqualToAnchor:panel.contentView.topAnchor constant:22.0],
        [image.centerXAnchor constraintEqualToAnchor:panel.contentView.centerXAnchor],
        [image.widthAnchor constraintEqualToConstant:82.0],
        [image.heightAnchor constraintEqualToConstant:82.0],

        [title.topAnchor constraintEqualToAnchor:image.bottomAnchor constant:8.0],
        [title.leadingAnchor constraintEqualToAnchor:panel.contentView.leadingAnchor constant:20.0],
        [title.trailingAnchor constraintEqualToAnchor:panel.contentView.trailingAnchor constant:-20.0],

        [subtitle.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:4.0],
        [subtitle.leadingAnchor constraintEqualToAnchor:panel.contentView.leadingAnchor constant:20.0],
        [subtitle.trailingAnchor constraintEqualToAnchor:panel.contentView.trailingAnchor constant:-20.0],

        [dot.topAnchor constraintEqualToAnchor:subtitle.bottomAnchor constant:14.0],
        [dot.trailingAnchor constraintEqualToAnchor:status.leadingAnchor constant:-7.0],
        [dot.centerYAnchor constraintEqualToAnchor:status.centerYAnchor],
        [dot.widthAnchor constraintEqualToConstant:10.0],
        [dot.heightAnchor constraintEqualToConstant:10.0],

        [status.centerXAnchor constraintEqualToAnchor:panel.contentView.centerXAnchor constant:8.0],
        [status.bottomAnchor constraintEqualToAnchor:panel.contentView.bottomAnchor constant:-18.0]
    ]];

    return panel;
}

- (void)showDeviceName:(NSString *)deviceName test:(BOOL)isTest {
    if (!AFReadBoolPreference(@"Enabled", YES)) return;

    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *keyword = AFReadStringPreference(@"Keyword", @"Soundcore");
        NSString *displayName = AFReadStringPreference(@"DisplayName", @"Soundcore");

        if (!isTest && !AFNameMatchesKeyword(deviceName)) return;

        if (!self.window) {
            self.window = [self makeWindow];
            self.card = [self buildCardIn:self.window.rootViewController.view];
        }

        self.titleLabel.text = displayName;
        self.subtitleLabel.text = isTest
            ? [NSString stringWithFormat:@"Тестовая карточка • правило «%@»", keyword]
            : [NSString stringWithFormat:@"%@ подключены", deviceName.length ? deviceName : displayName];

        self.window.hidden = NO;
        self.card.alpha = 0.0;
        self.card.transform = CGAffineTransformMakeTranslation(0.0, 28.0);

        [UIView animateWithDuration:0.30
                              delay:0.0
             usingSpringWithDamping:0.84
              initialSpringVelocity:0.45
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
            self.card.alpha = 1.0;
            self.card.transform = CGAffineTransformIdentity;
        } completion:nil];

        if (self.pendingHide) {
            dispatch_block_cancel(self.pendingHide);
            self.pendingHide = nil;
        }

        dispatch_block_t block = dispatch_block_create((dispatch_block_flags_t)0, ^{
            [UIView animateWithDuration:0.22 animations:^{
                self.card.alpha = 0.0;
                self.card.transform = CGAffineTransformMakeTranslation(0.0, 24.0);
            } completion:^(__unused BOOL finished) {
                self.window.hidden = YES;
                self.card.transform = CGAffineTransformIdentity;
            }];
        });

        self.pendingHide = block;
        dispatch_after(
            dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)),
            dispatch_get_main_queue(),
            block
        );
    });
}

@end

static NSArray *AFConnectedDevices(void) {
    Class managerClass = NSClassFromString(@"BluetoothManager");
    if (!managerClass) return @[];

    id manager = AFSend0(managerClass, NSSelectorFromString(@"sharedInstance"));
    if (!manager) return @[];

    id devices = AFSend0(manager, NSSelectorFromString(@"connectedDevices"));
    return [devices isKindOfClass:[NSArray class]] ? devices : @[];
}

static NSString *AFNameForBluetoothDevice(id device) {
    if (!device) return nil;

    for (NSString *selectorName in @[@"name", @"displayName"]) {
        NSString *value = AFStringFromPossibleValue(
            AFSend0(device, NSSelectorFromString(selectorName))
        );
        if (value.length > 0) return value;
    }

    return nil;
}

static NSString *AFFirstMatchingConnectedDevice(void) {
    for (id device in AFConnectedDevices()) {
        NSString *name = AFNameForBluetoothDevice(device);
        if (AFNameMatchesKeyword(name)) return name;
    }
    return nil;
}

@interface AFObserver : NSObject
@property(nonatomic,strong) NSString *lastMatchedDeviceName;
@property(nonatomic,strong) dispatch_source_t pollTimer;
+ (instancetype)shared;
- (void)start;
- (void)checkConnectedDevices;
@end

@implementation AFObserver

+ (instancetype)shared {
    static AFObserver *obj;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        obj = [AFObserver new];
    });
    return obj;
}

- (void)start {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

    for (NSString *name in @[
        @"BluetoothDeviceConnectSuccessNotification",
        @"BluetoothDeviceConnectionChangedNotification",
        @"BluetoothDeviceConnectedNotification",
        @"BluetoothConnectionStatusChangedNotification"
    ]) {
        [center addObserver:self
                   selector:@selector(bluetoothChanged:)
                       name:name
                     object:nil];
    }

    Class managerClass = NSClassFromString(@"BluetoothManager");
    AFSend0(managerClass, NSSelectorFromString(@"sharedInstance"));

    if (!self.pollTimer) {
        dispatch_source_t timer =
            dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());

        if (timer) {
            dispatch_source_set_timer(
                timer,
                dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)),
                (uint64_t)(1.5 * NSEC_PER_SEC),
                (uint64_t)(0.2 * NSEC_PER_SEC)
            );

            __weak AFObserver *weakSelf = self;
            dispatch_source_set_event_handler(timer, ^{
                [weakSelf checkConnectedDevices];
            });

            self.pollTimer = timer;
            dispatch_resume(timer);
        }
    }
}

- (void)bluetoothChanged:(__unused NSNotification *)note {
    [self checkConnectedDevices];
}

- (void)checkConnectedDevices {
    if (!AFReadBoolPreference(@"Enabled", YES)) {
        self.lastMatchedDeviceName = nil;
        return;
    }

    NSString *current = AFFirstMatchingConnectedDevice();

    if (current.length == 0) {
        self.lastMatchedDeviceName = nil;
        return;
    }

    if (![self.lastMatchedDeviceName isEqualToString:current]) {
        self.lastMatchedDeviceName = current;
        [[AFPopupController shared] showDeviceName:current test:NO];
    }
}

@end

%hook SBApplication

- (NSArray *)tags {
    NSArray *originalTags = %orig;

    if (![[self bundleIdentifier] isEqualToString:@"com.x7.airfakeapp"]) {
        return originalTags;
    }

    BOOL hideIcon = AFReadBoolPreference(@"HideAppIcon", NO);
    BOOL alreadyHidden = [originalTags containsObject:@"hidden"];

    if (hideIcon == alreadyHidden) {
        return originalTags;
    }

    NSMutableArray *updated =
        originalTags ? [originalTags mutableCopy] : [NSMutableArray array];

    if (hideIcon) {
        [updated addObject:@"hidden"];
    } else {
        [updated removeObject:@"hidden"];
    }

    return [updated copy];
}

%end

static void AFDarwinCallback(
    __unused CFNotificationCenterRef center,
    __unused void *observer,
    CFStringRef name,
    __unused const void *object,
    __unused CFDictionaryRef userInfo
) {
    NSString *notification = (__bridge NSString *)name;

    if ([notification isEqualToString:AFTestDarwinNotification]) {
        [[AFPopupController shared] showDeviceName:@"Soundcore Test" test:YES];
        return;
    }

    if ([notification isEqualToString:AFPrefsChangedDarwinNotification]) {
        CFPreferencesAppSynchronize((__bridge CFStringRef)AFPrefsDomain);
        [[AFObserver shared] checkConnectedDevices];
        return;
    }

    if ([notification isEqualToString:AFRespringDarwinNotification]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            kill(getpid(), SIGTERM);
        });
    }
}

%ctor {
    @autoreleasepool {
        if (![[NSProcessInfo processInfo].processName isEqualToString:@"SpringBoard"]) {
            return;
        }

        CFNotificationCenterRef darwin = CFNotificationCenterGetDarwinNotifyCenter();

        for (NSString *name in @[
            AFTestDarwinNotification,
            AFPrefsChangedDarwinNotification,
            AFRespringDarwinNotification
        ]) {
            CFNotificationCenterAddObserver(
                darwin,
                NULL,
                AFDarwinCallback,
                (__bridge CFStringRef)name,
                NULL,
                CFNotificationSuspensionBehaviorDeliverImmediately
            );
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [[AFObserver shared] start];
        });
    }
}
