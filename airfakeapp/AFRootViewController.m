#import "AFRootViewController.h"
#import <CoreFoundation/CoreFoundation.h>
#import <spawn.h>
#import <unistd.h>
extern char **environ;

static NSString * const AFPrefsDomain = @"com.x7.airfake";
static NSString * const AFTestDarwinNotification = @"com.x7.airfake/test";
static NSString * const AFPrefsChangedDarwinNotification = @"com.x7.airfake/preferences.changed";

static id AFReadPreference(NSString *key) {
    CFPropertyListRef value = CFPreferencesCopyValue((__bridge CFStringRef)key, (__bridge CFStringRef)AFPrefsDomain, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    return value ? CFBridgingRelease(value) : nil;
}
static void AFWritePreference(NSString *key, id value) {
    CFPreferencesSetValue((__bridge CFStringRef)key, (__bridge CFPropertyListRef)value, (__bridge CFStringRef)AFPrefsDomain, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    CFPreferencesSynchronize((__bridge CFStringRef)AFPrefsDomain, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
}
static void AFPostDarwin(NSString *name) {
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge CFStringRef)name, NULL, NULL, YES);
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

    UIScrollView *scroll = [UIScrollView new];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:scroll];
    UIStackView *stack = [UIStackView new];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 14;
    stack.layoutMargins = UIEdgeInsetsMake(24, 18, 30, 18);
    stack.layoutMarginsRelativeArrangement = YES;
    [scroll addSubview:stack];

    [NSLayoutConstraint activateConstraints:@[
        [scroll.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [scroll.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [scroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [scroll.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [stack.topAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.topAnchor],
        [stack.leadingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.leadingAnchor],
        [stack.trailingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.trailingAnchor],
        [stack.bottomAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.bottomAnchor],
        [stack.widthAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.widthAnchor]
    ]];

    UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"AirFakeIcon"]];
    icon.translatesAutoresizingMaskIntoConstraints = NO;
    icon.contentMode = UIViewContentModeScaleAspectFit;
    icon.layer.cornerRadius = 22;
    icon.layer.masksToBounds = YES;
    [icon.widthAnchor constraintEqualToConstant:92].active = YES;
    [icon.heightAnchor constraintEqualToConstant:92].active = YES;
    UIView *holder = [UIView new];
    [holder addSubview:icon];
    [NSLayoutConstraint activateConstraints:@[
        [icon.centerXAnchor constraintEqualToAnchor:holder.centerXAnchor],
        [icon.topAnchor constraintEqualToAnchor:holder.topAnchor],
        [icon.bottomAnchor constraintEqualToAnchor:holder.bottomAnchor]
    ]];
    [stack addArrangedSubview:holder];

    UILabel *title = [UILabel new];
    title.text = @"AirFake 0.2";
    title.font = [UIFont systemFontOfSize:28 weight:UIFontWeightBold];
    title.textAlignment = NSTextAlignmentCenter;
    [stack addArrangedSubview:title];

    UILabel *subtitle = [UILabel new];
    subtitle.text = @"AirPods-style popup для обычных Bluetooth-наушников";
    subtitle.font = [UIFont systemFontOfSize:15];
    subtitle.textColor = UIColor.secondaryLabelColor;
    subtitle.numberOfLines = 0;
    subtitle.textAlignment = NSTextAlignmentCenter;
    [stack addArrangedSubview:subtitle];

    UIView *card = [UIView new];
    card.backgroundColor = UIColor.secondarySystemGroupedBackgroundColor;
    card.layer.cornerRadius = 18;
    UIStackView *cardStack = [UIStackView new];
    cardStack.translatesAutoresizingMaskIntoConstraints = NO;
    cardStack.axis = UILayoutConstraintAxisVertical;
    cardStack.spacing = 12;
    [card addSubview:cardStack];
    [NSLayoutConstraint activateConstraints:@[
        [cardStack.topAnchor constraintEqualToAnchor:card.topAnchor constant:16],
        [cardStack.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],
        [cardStack.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16],
        [cardStack.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-16]
    ]];

    self.enabledSwitch = [UISwitch new];
    [cardStack addArrangedSubview:[self switchRow:@"Включить AirFake" control:self.enabledSwitch]];
    [cardStack addArrangedSubview:[self smallLabel:@"Искать в имени Bluetooth"]];
    self.keywordField = [self textField:@"Soundcore"];
    [cardStack addArrangedSubview:self.keywordField];
    [cardStack addArrangedSubview:[self smallLabel:@"Название на карточке"]];
    self.displayNameField = [self textField:@"Soundcore"];
    [cardStack addArrangedSubview:self.displayNameField];
    self.hideIconSwitch = [UISwitch new];
    [self.hideIconSwitch addTarget:self action:@selector(hideIconChanged:) forControlEvents:UIControlEventValueChanged];
    [cardStack addArrangedSubview:[self switchRow:@"Скрыть иконку AirFake" control:self.hideIconSwitch]];
    UILabel *hint = [self smallLabel:@"После скрытия вернуть иконку можно через Настройки iOS → AirFake. Для изменения видимости нужен Respring."];
    hint.numberOfLines = 0;
    [cardStack addArrangedSubview:hint];
    [stack addArrangedSubview:card];

    UIButton *save = [self button:@"Сохранить настройки" filled:YES];
    [save addTarget:self action:@selector(saveTapped) forControlEvents:UIControlEventTouchUpInside];
    [stack addArrangedSubview:save];
    UIButton *test = [self button:@"Показать тестовую карточку" filled:NO];
    [test addTarget:self action:@selector(testTapped) forControlEvents:UIControlEventTouchUpInside];
    [stack addArrangedSubview:test];
    UIButton *respring = [self button:@"Применить и сделать Respring" filled:NO];
    [respring addTarget:self action:@selector(respringTapped) forControlEvents:UIControlEventTouchUpInside];
    [stack addArrangedSubview:respring];

    self.statusLabel = [UILabel new];
    self.statusLabel.font = [UIFont systemFontOfSize:13];
    self.statusLabel.textColor = UIColor.secondaryLabelColor;
    self.statusLabel.numberOfLines = 0;
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    [stack addArrangedSubview:self.statusLabel];
    [self loadPreferences];
}

- (UILabel *)smallLabel:(NSString *)text {
    UILabel *l = [UILabel new]; l.text = text; l.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium]; l.textColor = UIColor.secondaryLabelColor; return l;
}
- (UITextField *)textField:(NSString *)placeholder {
    UITextField *f = [UITextField new];
    f.placeholder = placeholder; f.delegate = self; f.backgroundColor = UIColor.tertiarySystemGroupedBackgroundColor; f.layer.cornerRadius = 11; f.clearButtonMode = UITextFieldViewModeWhileEditing; f.returnKeyType = UIReturnKeyDone; f.autocorrectionType = UITextAutocorrectionTypeNo; f.autocapitalizationType = UITextAutocapitalizationTypeNone; f.font = [UIFont systemFontOfSize:16];
    UIView *pad = [[UIView alloc] initWithFrame:CGRectMake(0,0,12,1)]; f.leftView = pad; f.leftViewMode = UITextFieldViewModeAlways; [f.heightAnchor constraintEqualToConstant:46].active = YES; return f;
}
- (UIStackView *)switchRow:(NSString *)title control:(UISwitch *)control {
    UILabel *label = [UILabel new]; label.text = title; label.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium]; label.numberOfLines = 0;
    UIStackView *row = [[UIStackView alloc] initWithArrangedSubviews:@[label, control]]; row.axis = UILayoutConstraintAxisHorizontal; row.alignment = UIStackViewAlignmentCenter; row.distribution = UIStackViewDistributionEqualSpacing; row.spacing = 10; return row;
}
- (UIButton *)button:(NSString *)title filled:(BOOL)filled {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem]; [b setTitle:title forState:UIControlStateNormal]; b.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold]; b.layer.cornerRadius = 14; b.layer.masksToBounds = YES; b.contentEdgeInsets = UIEdgeInsetsMake(13,14,13,14);
    if (filled) { b.backgroundColor = UIColor.systemBlueColor; [b setTitleColor:UIColor.whiteColor forState:UIControlStateNormal]; } else { b.backgroundColor = UIColor.secondarySystemGroupedBackgroundColor; }
    return b;
}
- (void)loadPreferences {
    id enabled=AFReadPreference(@"Enabled"), keyword=AFReadPreference(@"Keyword"), display=AFReadPreference(@"DisplayName"), hide=AFReadPreference(@"HideAppIcon");
    self.enabledSwitch.on = enabled ? [enabled boolValue] : YES;
    self.keywordField.text = [keyword isKindOfClass:[NSString class]] ? keyword : @"Soundcore";
    self.displayNameField.text = [display isKindOfClass:[NSString class]] ? display : @"Soundcore";
    self.hideIconSwitch.on = hide ? [hide boolValue] : NO;
}
- (void)savePreferences {
    NSString *keyword=[self.keywordField.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    NSString *display=[self.displayNameField.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (!keyword.length) keyword=@"Soundcore"; if (!display.length) display=keyword;
    AFWritePreference(@"Enabled", @(self.enabledSwitch.isOn)); AFWritePreference(@"Keyword", keyword); AFWritePreference(@"DisplayName", display); AFWritePreference(@"HideAppIcon", @(self.hideIconSwitch.isOn)); AFPostDarwin(AFPrefsChangedDarwinNotification);
}
- (void)saveTapped { [self.view endEditing:YES]; [self savePreferences]; self.statusLabel.text=@"Сохранено. Правила Bluetooth применяются сразу."; }
- (void)testTapped { [self.view endEditing:YES]; [self savePreferences]; AFPostDarwin(AFTestDarwinNotification); self.statusLabel.text=@"Команда тестовой карточки отправлена в SpringBoard."; }
- (void)hideIconChanged:(UISwitch *)sender { [self savePreferences]; self.statusLabel.text = sender.isOn ? @"Иконка будет скрыта после Respring." : @"Иконка вернётся после Respring."; }
- (void)respringTapped {
    [self.view endEditing:YES]; [self savePreferences];
    const char *paths[] = { "/var/jb/usr/bin/killall", "/usr/bin/killall", NULL };
    for (int i=0; paths[i]; i++) if (access(paths[i], X_OK)==0) { pid_t pid=0; char * const args[]={(char*)"killall",(char*)"-9",(char*)"SpringBoard",NULL}; if (posix_spawn(&pid, paths[i], NULL, NULL, args, environ)==0) return; }
    self.statusLabel.text=@"Авто-Respring не сработал. Сделай Respring через Dopamine/Sileo.";
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField { [textField resignFirstResponder]; return YES; }
@end
