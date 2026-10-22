#import <UIKit/UIKit.h>
#import <CoreFoundation/CoreFoundation.h>
#import <objc/message.h>

static NSString * const AFPrefsDomain = @"com.x7.airfake";
static NSString * const AFTestDarwinNotification = @"com.x7.airfake/test";
static NSString * const AFPrefsChangedDarwinNotification = @"com.x7.airfake/preferences.changed";

static id AFSend0(id obj, SEL sel) {
    if (!obj || !sel || ![obj respondsToSelector:sel]) return nil;
    return ((id (*)(id, SEL))objc_msgSend)(obj, sel);
}

static NSString *AFStringFromPossibleValue(id value) {
    if ([value isKindOfClass:[NSString class]]) return value;
    if ([value respondsToSelector:@selector(stringValue)]) return [value stringValue];
    return nil;
}

static NSString *AFReadStringPreference(NSString *key, NSString *fallback) {
    CFPreferencesAppSynchronize((__bridge CFStringRef)AFPrefsDomain);

    CFPropertyListRef value =
        CFPreferencesCopyAppValue(
            (__bridge CFStringRef)key,
            (__bridge CFStringRef)AFPrefsDomain
        );

    if (!value) return fallback;

    id obj = CFBridgingRelease(value);

    if ([obj isKindOfClass:[NSString class]] && [obj length] > 0) {
        return obj;
    }

    return fallback;
}

static BOOL AFReadBoolPreference(NSString *key, BOOL fallback) {
    CFPreferencesAppSynchronize((__bridge CFStringRef)AFPrefsDomain);

    CFPropertyListRef value =
        CFPreferencesCopyAppValue(
            (__bridge CFStringRef)key,
            (__bridge CFStringRef)AFPrefsDomain
        );

    if (!value) return fallback;

    id obj = CFBridgingRelease(value);

    if ([obj respondsToSelector:@selector(boolValue)]) {
        return [obj boolValue];
    }

    return fallback;
}

@interface AFPopupController : NSObject

@property(nonatomic,strong) UIWindow *window;
@property(nonatomic,strong) UIView *card;
@property(nonatomic,strong) UILabel *titleLabel;
@property(nonatomic,strong) UILabel *subtitleLabel;
@property(nonatomic,strong) UIImageView *headphonesImage;
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
    UIWindow *w = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];

    w.windowLevel = UIWindowLevelAlert + 120.0;
    w.backgroundColor = UIColor.clearColor;
    w.userInteractionEnabled = NO;

    UIViewController *vc = [UIViewController new];
    vc.view.backgroundColor = UIColor.clearColor;

    w.rootViewController = vc;

    return w;
}

- (UIView *)buildCardIn:(UIView *)host {

    UIBlurEffect *blur =
        [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterial];

    UIVisualEffectView *panel =
        [[UIVisualEffectView alloc] initWithEffect:blur];

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

    UIImageView *img =
        [[UIImageView alloc] initWithImage:
            [UIImage systemImageNamed:@"headphones"
                withConfiguration:
                    [UIImageSymbolConfiguration
                        configurationWithPointSize:66
                        weight:UIImageSymbolWeightRegular]
            ]
        ];

    img.translatesAutoresizingMaskIntoConstraints = NO;
    img.tintColor = UIColor.labelColor;
    img.contentMode = UIViewContentModeScaleAspectFit;

    [panel.contentView addSubview:img];

    self.headphonesImage = img;

    UILabel *title = [UILabel new];

    title.translatesAutoresizingMaskIntoConstraints = NO;
    title.font = [UIFont systemFontOfSize:24 weight:UIFontWeightSemibold];
    title.textAlignment = NSTextAlignmentCenter;
    title.textColor = UIColor.labelColor;
    title.numberOfLines = 1;

    [panel.contentView addSubview:title];

    self.titleLabel = title;

    UILabel *sub = [UILabel new];

    sub.translatesAutoresizingMaskIntoConstraints = NO;
    sub.font = [UIFont systemFontOfSize:15 weight:UIFontWeightRegular];
    sub.textAlignment = NSTextAlignmentCenter;
    sub.textColor = UIColor.secondaryLabelColor;
    sub.numberOfLines = 2;

    [panel.contentView addSubview:sub];

    self.subtitleLabel = sub;

    UIView *dot = [UIView new];

    dot.translatesAutoresizingMaskIntoConstraints = NO;
    dot.backgroundColor = UIColor.systemGreenColor;
    dot.layer.cornerRadius = 5.0;

    [panel.contentView addSubview:dot];

    UILabel *status = [UILabel new];

    status.translatesAutoresizingMaskIntoConstraints = NO;
    status.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    status.textColor = UIColor.secondaryLabelColor;
    status.text = @"Bluetooth";

    [panel.contentView addSubview:status];

    [NSLayoutConstraint activateConstraints:@[

        [img.topAnchor constraintEqualToAnchor:panel.contentView.topAnchor constant:22.0],
        [img.centerXAnchor constraintEqualToAnchor:panel.contentView.centerXAnchor],
        [img.widthAnchor constraintEqualToConstant:82.0],
        [img.heightAnchor constraintEqualToConstant:82.0],

        [title.topAnchor constraintEqualToAnchor:img.bottomAnchor constant:8.0],
        [title.leadingAnchor constraintEqualToAnchor:panel.contentView.leadingAnchor constant:20.0],
        [title.trailingAnchor constraintEqualToAnchor:panel.contentView.trailingAnchor constant:-20.0],

        [sub.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:4.0],
        [sub.leadingAnchor constraintEqualToAnchor:panel.contentView.leadingAnchor constant:20.0],
        [sub.trailingAnchor constraintEqualToAnchor:panel.contentView.trailingAnchor constant:-20.0],

        [dot.topAnchor constraintEqualToAnchor:sub.bottomAnchor constant:14.0],
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

        NSString *keyword =
            AFReadStringPreference(@"Keyword", @"Soundcore");

        NSString *customTitle =
            AFReadStringPreference(@"DisplayName", @"Soundcore");

        if (!isTest) {

            NSRange match =
                [deviceName rangeOfString:keyword
                                 options:
                                     NSCaseInsensitiveSearch |
                                     NSDiacriticInsensitiveSearch];

            if (match.location == NSNotFound) {
                return;
            }
        }

        if (!self.window) {

            self.window = [self makeWindow];

            self.card =
                [self buildCardIn:self.window.rootViewController.view];
        }

        self.titleLabel.text = customTitle;

        if (isTest) {

            self.subtitleLabel.text =
                [NSString stringWithFormat:
                    @"Тестовая карточка • правило «%@»",
                    keyword];

        } else {

            self.subtitleLabel.text =
                [NSString stringWithFormat:
                    @"%@ подключены",
                    deviceName ?: customTitle];
        }

        self.window.hidden = NO;

        self.card.alpha = 0.0;

        self.card.transform =
            CGAffineTransformMakeTranslation(0, 28);

        [UIView animateWithDuration:0.30
                              delay:0
             usingSpringWithDamping:0.84
              initialSpringVelocity:0.45
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{

            self.card.alpha = 1.0;

            self.card.transform =
                CGAffineTransformIdentity;

        } completion:nil];

        if (self.pendingHide) {

            dispatch_block_cancel(self.pendingHide);

            self.pendingHide = nil;
        }

        dispatch_block_t block =
            dispatch_block_create(
                (dispatch_block_flags_t)0,
                ^{

                    [UIView animateWithDuration:0.22
                                     animations:^{

                        self.card.alpha = 0.0;

                        self.card.transform =
                            CGAffineTransformMakeTranslation(0, 24);

                    } completion:^(BOOL finished) {

                        self.window.hidden = YES;

                        self.card.transform =
                            CGAffineTransformIdentity;
                    }];
                });

        self.pendingHide = block;

        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                (int64_t)(5.0 * NSEC_PER_SEC)
            ),
            dispatch_get_main_queue(),
            block
        );
    });
}

@end

static NSString *AFDeviceNameFromNotification(NSNotification *note) {

    id candidate = note.object;

    if (!candidate &&
        [note.userInfo isKindOfClass:[NSDictionary class]]) {

        candidate =
            note.userInfo[@"device"] ?:
            note.userInfo[@"Device"] ?:
            note.userInfo[@"BluetoothDevice"];
    }

    NSArray<NSString *> *selectors =
        @[
            @"name",
            @"displayName",
            @"address"
        ];

    for (NSString *selName in selectors) {

        id value =
            AFSend0(
                candidate,
                NSSelectorFromString(selName)
            );

        NSString *text =
            AFStringFromPossibleValue(value);

        if (text.length > 0) {
            return text;
        }
    }

    return nil;
}

static NSArray *AFConnectedDevices(void) {

    Class managerClass =
        NSClassFromString(@"BluetoothManager");

    if (!managerClass) {
        return @[];
    }

    id manager =
        AFSend0(
            managerClass,
            NSSelectorFromString(@"sharedInstance")
        );

    if (!manager) {
        return @[];
    }

    id devices =
        AFSend0(
            manager,
            NSSelectorFromString(@"connectedDevices")
        );

    if ([devices isKindOfClass:[NSArray class]]) {
        return devices;
    }

    return @[];
}

static NSString *AFFirstMatchingConnectedDevice(void) {

    NSString *keyword =
        AFReadStringPreference(@"Keyword", @"Soundcore");

    for (id device in AFConnectedDevices()) {

        NSString *name = nil;

        NSArray *nameSelectors =
            @[
                @"name",
                @"displayName"
            ];

        for (NSString *selName in nameSelectors) {

            id value =
                AFSend0(
                    device,
                    NSSelectorFromString(selName)
                );

            name =
                AFStringFromPossibleValue(value);

            if (name.length > 0) {
                break;
            }
        }

        if (name.length > 0) {

            NSRange match =
                [name rangeOfString:keyword
                           options:
                               NSCaseInsensitiveSearch |
                               NSDiacriticInsensitiveSearch];

            if (match.location != NSNotFound) {
                return name;
            }
        }
    }

    return nil;
}

@interface AFObserver : NSObject

+ (instancetype)shared;
- (void)start;

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

    NSNotificationCenter *nc =
        [NSNotificationCenter defaultCenter];

    NSArray<NSString *> *names =
        @[
            @"BluetoothDeviceConnectSuccessNotification",
            @"BluetoothDeviceConnectionChangedNotification",
            @"BluetoothDeviceConnectedNotification",
            @"BluetoothConnectionStatusChangedNotification"
        ];

    for (NSString *name in names) {

        [nc addObserver:self
               selector:@selector(bluetoothChanged:)
                   name:name
                 object:nil];
    }

    Class managerClass =
        NSClassFromString(@"BluetoothManager");

    AFSend0(
        managerClass,
        NSSelectorFromString(@"sharedInstance")
    );
}

- (void)bluetoothChanged:(NSNotification *)note {

    if (!AFReadBoolPreference(@"Enabled", YES)) {
        return;
    }

    NSString *name =
        AFDeviceNameFromNotification(note);

    if (name.length == 0) {

        name =
            AFFirstMatchingConnectedDevice();
    }

    if (name.length > 0) {

        [[AFPopupController shared]
            showDeviceName:name
                      test:NO];
    }
}

@end

static void AFDarwinCallback(
    CFNotificationCenterRef center,
    void *observer,
    CFStringRef name,
    const void *object,
    CFDictionaryRef userInfo
) {

    NSString *notification =
        (__bridge NSString *)name;

    if ([notification
            isEqualToString:
                AFTestDarwinNotification]) {

        [[AFPopupController shared]
            showDeviceName:@"Soundcore Test"
                      test:YES];

    } else if ([notification
                   isEqualToString:
                       AFPrefsChangedDarwinNotification]) {

        CFPreferencesAppSynchronize(
            (__bridge CFStringRef)AFPrefsDomain
        );
    }
}

%ctor {

    @autoreleasepool {

        if (![[NSProcessInfo processInfo].processName
                isEqualToString:@"SpringBoard"]) {

            return;
        }

        CFNotificationCenterRef darwin =
            CFNotificationCenterGetDarwinNotifyCenter();

        CFNotificationCenterAddObserver(
            darwin,
            NULL,
            AFDarwinCallback,
            (__bridge CFStringRef)AFTestDarwinNotification,
            NULL,
            CFNotificationSuspensionBehaviorDeliverImmediately
        );

        CFNotificationCenterAddObserver(
            darwin,
            NULL,
            AFDarwinCallback,
            (__bridge CFStringRef)AFPrefsChangedDarwinNotification,
            NULL,
            CFNotificationSuspensionBehaviorDeliverImmediately
        );

        dispatch_async(
            dispatch_get_main_queue(),
            ^{

                [[AFObserver shared] start];

            }
        );
    }
}
