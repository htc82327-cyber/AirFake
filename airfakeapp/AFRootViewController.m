#import "AFRootViewController.h"
#import <CoreFoundation/CoreFoundation.h>

static NSString * const AFPrefsDomain = @"com.x7.airfake";
static NSString * const AFTestDarwinNotification = @"com.x7.airfake/test";
static NSString * const AFPrefsChangedDarwinNotification = @"com.x7.airfake/preferences.changed";
static NSString * const AFRespringDarwinNotification = @"com.x7.airfake/respring";

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

static void AFWritePreference(NSString *key, id value) {
    CFPreferencesSetValue(
        (__bridge CFStringRef)key,
        (__bridge CFPropertyListRef)value,
        (__bridge CFStringRef)AFPrefsDomain,
        kCFPreferencesCurrentUser,
        kCFPreferencesAnyHost
    );

    CFPreferencesSynchronize(
        (__bridge CFStringRef)AFPrefsDomain,
        kCFPreferencesCurrentUser,
        kCFPreferencesAnyHost
    );
}

static void AFPostDarwin(NSString *name) {
    CFNotificationCenterPostNotification(
        CFNotificationCenterGetDarwinNotifyCenter(),
        (__bridge CFStringRef)name,
        NULL,
        NULL,
        YES
    );
}

@interface AFRootViewController () <UITextFieldDelegate>
@property(nonatomic,strong) UISwitch *enabledSwitch;
@property(nonatomic,strong) UISwitch *hideIconSwitch;
@property(nonatomic,strong) UITextField *keywordField;
@property(nonatomic,strong) UITextField *displayNameField;
@property(nonatomic,strong) UILabel *statusLabel;
@end

@implementation AFRootViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"AirFake";
    self.view.backgroundColor = UIColor.systemGroupedBackgroundColor;

    UIScrollView *scrollView = [UIScrollView new];
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:scrollView];

    UIStackView *stack = [UIStackView new];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 14.0;
    stack.layoutMargins = UIEdgeInsetsMake(24.0, 18.0, 30.0, 18.0);
    stack.layoutMarginsRelativeArrangement = YES;
    [scrollView addSubview:stack];

    [NSLayoutConstraint activateConstraints:@[
        [scrollView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [stack.topAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.topAnchor],
        [stack.leadingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.leadingAnchor],
        [stack.trailingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.trailingAnchor],
        [stack.bottomAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.bottomAnchor],
        [stack.widthAnchor constraintEqualToAnchor:scrollView.frameLayoutGuide.widthAnchor]
    ]];

    UIImageView *icon =
        [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"AirFakeIcon"]];
    icon.translatesAutoresizingMaskIntoConstraints = NO;
    icon.contentMode = UIViewContentModeScaleAspectFit;
    icon.layer.cornerRadius = 22.0;
    icon.layer.masksToBounds = YES;

    [NSLayoutConstraint activateConstraints:@[
        [icon.widthAnchor constraintEqualToConstant:92.0],
        [icon.heightAnchor constraintEqualToConstant:92.0]
    ]];

    UIView *iconHolder = [UIView new];
    [iconHolder addSubview:icon];

    [NSLayoutConstraint activateConstraints:@[
        [icon.centerXAnchor constraintEqualToAnchor:iconHolder.centerXAnchor],
        [icon.topAnchor constraintEqualToAnchor:iconHolder.topAnchor],
        [icon.bottomAnchor constraintEqualToAnchor:iconHolder.bottomAnchor]
    ]];

    [stack addArrangedSubview:iconHolder];

    UILabel *title = [UILabel new];
    title.text = @"AirFake 0.2.1";
    title.font = [UIFont systemFontOfSize:28.0 weight:UIFontWeightBold];
    title.textAlignment = NSTextAlignmentCenter;
    [stack addArrangedSubview:title];

    UILabel *subtitle = [UILabel new];
    subtitle.text = @"AirPods-style popup для обычных Bluetooth-наушников";
    subtitle.font = [UIFont systemFontOfSize:15.0];
    subtitle.textColor = UIColor.secondaryLabelColor;
    subtitle.numberOfLines = 0;
    subtitle.textAlignment = NSTextAlignmentCenter;
    [stack addArrangedSubview:subtitle];

    UIView *card = [UIView new];
    card.backgroundColor = UIColor.secondarySystemGroupedBackgroundColor;
    card.layer.cornerRadius = 18.0;

    UIStackView *cardStack = [UIStackView new];
    cardStack.translatesAutoresizingMaskIntoConstraints = NO;
    cardStack.axis = UILayoutConstraintAxisVertical;
    cardStack.spacing = 12.0;
    [card addSubview:cardStack];

    [NSLayoutConstraint activateConstraints:@[
        [cardStack.topAnchor constraintEqualToAnchor:card.topAnchor constant:16.0],
        [cardStack.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16.0],
        [cardStack.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16.0],
        [cardStack.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-16.0]
    ]];

    self.enabledSwitch = [UISwitch new];
    [cardStack addArrangedSubview:
        [self switchRow:@"Включить AirFake" control:self.enabledSwitch]];

    [cardStack addArrangedSubview:[self smallLabel:@"Искать в имени Bluetooth"]];
    self.keywordField = [self textField:@"Soundcore"];
    [cardStack addArrangedSubview:self.keywordField];

    [cardStack addArrangedSubview:[self smallLabel:@"Название на карточке"]];
    self.displayNameField = [self textField:@"Soundcore"];
    [cardStack addArrangedSubview:self.displayNameField];

    self.hideIconSwitch = [UISwitch new];
    [cardStack addArrangedSubview:
        [self switchRow:@"Скрыть иконку AirFake" control:self.hideIconSwitch]];

    UILabel *hint =
        [self smallLabel:
            @"Если скрыть иконку, вернуть её можно через Настройки iOS → AirFake. "
             "После изменения видимости нажми «Применить и сделать Respring»."];
    hint.numberOfLines = 0;
    [cardStack addArrangedSubview:hint];

    [stack addArrangedSubview:card];

    UIButton *saveButton = [self button:@"Сохранить настройки" filled:YES];
    [saveButton addTarget:self
                   action:@selector(saveTapped)
         forControlEvents:UIControlEventTouchUpInside];
    [stack addArrangedSubview:saveButton];

    UIButton *testButton = [self button:@"Показать тестовую карточку" filled:NO];
    [testButton addTarget:self
                   action:@selector(testTapped)
         forControlEvents:UIControlEventTouchUpInside];
    [stack addArrangedSubview:testButton];

    UIButton *respringButton =
        [self button:@"Применить и сделать Respring" filled:NO];
    [respringButton addTarget:self
                       action:@selector(respringTapped)
             forControlEvents:UIControlEventTouchUpInside];
    [stack addArrangedSubview:respringButton];

    self.statusLabel = [UILabel new];
    self.statusLabel.font = [UIFont systemFontOfSize:13.0];
    self.statusLabel.textColor = UIColor.secondaryLabelColor;
    self.statusLabel.numberOfLines = 0;
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    [stack addArrangedSubview:self.statusLabel];

    [self loadPreferences];
}

- (UILabel *)smallLabel:(NSString *)text {
    UILabel *label = [UILabel new];
    label.text = text;
    label.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightMedium];
    label.textColor = UIColor.secondaryLabelColor;
    return label;
}

- (UITextField *)textField:(NSString *)placeholder {
    UITextField *field = [UITextField new];
    field.placeholder = placeholder;
    field.delegate = self;
    field.backgroundColor = UIColor.tertiarySystemGroupedBackgroundColor;
    field.layer.cornerRadius = 11.0;
    field.clearButtonMode = UITextFieldViewModeWhileEditing;
    field.returnKeyType = UIReturnKeyDone;
    field.autocorrectionType = UITextAutocorrectionTypeNo;
    field.autocapitalizationType = UITextAutocapitalizationTypeNone;
    field.font = [UIFont systemFontOfSize:16.0];

    UIView *padding = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, 1)];
    field.leftView = padding;
    field.leftViewMode = UITextFieldViewModeAlways;

    [field.heightAnchor constraintEqualToConstant:46.0].active = YES;
    return field;
}

- (UIStackView *)switchRow:(NSString *)title control:(UISwitch *)control {
    UILabel *label = [UILabel new];
    label.text = title;
    label.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightMedium];
    label.numberOfLines = 0;

    UIStackView *row =
        [[UIStackView alloc] initWithArrangedSubviews:@[label, control]];
    row.axis = UILayoutConstraintAxisHorizontal;
    row.alignment = UIStackViewAlignmentCenter;
    row.distribution = UIStackViewDistributionEqualSpacing;
    row.spacing = 10.0;
    return row;
}

- (UIButton *)button:(NSString *)title filled:(BOOL)filled {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font =
        [UIFont systemFontOfSize:16.0 weight:UIFontWeightSemibold];
    button.layer.cornerRadius = 14.0;
    button.layer.masksToBounds = YES;
    button.contentEdgeInsets = UIEdgeInsetsMake(13.0, 14.0, 13.0, 14.0);

    if (filled) {
        button.backgroundColor = UIColor.systemBlueColor;
        [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    } else {
        button.backgroundColor = UIColor.secondarySystemGroupedBackgroundColor;
    }

    return button;
}

- (void)loadPreferences {
    id enabled = AFReadPreference(@"Enabled");
    id keyword = AFReadPreference(@"Keyword");
    id displayName = AFReadPreference(@"DisplayName");
    id hideIcon = AFReadPreference(@"HideAppIcon");

    self.enabledSwitch.on = enabled ? [enabled boolValue] : YES;
    self.keywordField.text =
        [keyword isKindOfClass:[NSString class]] ? keyword : @"Soundcore";
    self.displayNameField.text =
        [displayName isKindOfClass:[NSString class]] ? displayName : @"Soundcore";
    self.hideIconSwitch.on = hideIcon ? [hideIcon boolValue] : NO;
}

- (void)savePreferences {
    NSString *keyword =
        [self.keywordField.text
            stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];

    NSString *displayName =
        [self.displayNameField.text
            stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];

    if (keyword.length == 0) keyword = @"Soundcore";
    if (displayName.length == 0) displayName = keyword;

    AFWritePreference(@"Enabled", @(self.enabledSwitch.isOn));
    AFWritePreference(@"Keyword", keyword);
    AFWritePreference(@"DisplayName", displayName);
    AFWritePreference(@"HideAppIcon", @(self.hideIconSwitch.isOn));

    AFPostDarwin(AFPrefsChangedDarwinNotification);
}

- (void)saveTapped {
    [self.view endEditing:YES];
    [self savePreferences];
    self.statusLabel.text = @"Сохранено.";
}

- (void)testTapped {
    [self.view endEditing:YES];
    [self savePreferences];
    AFPostDarwin(AFTestDarwinNotification);
    self.statusLabel.text = @"Команда тестовой карточки отправлена в SpringBoard.";
}

- (void)respringTapped {
    [self.view endEditing:YES];
    [self savePreferences];
    self.statusLabel.text = @"Выполняется Respring…";
    AFPostDarwin(AFRespringDarwinNotification);
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end
