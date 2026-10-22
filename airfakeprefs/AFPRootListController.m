#import "AFPRootListController.h"
#import <Preferences/PSSpecifier.h>
#import <CoreFoundation/CoreFoundation.h>
static NSString * const AFPrefsDomain=@"com.x7.airfake";
static NSString * const AFTestDarwinNotification=@"com.x7.airfake/test";
static NSString * const AFChangedDarwinNotification=@"com.x7.airfake/preferences.changed";
@implementation AFPRootListController
- (NSArray *)specifiers { if (!_specifiers) _specifiers=[self loadSpecifiersFromPlistName:@"Root" target:self]; return _specifiers; }
- (id)readPreferenceValue:(PSSpecifier *)specifier { NSString *key=[specifier propertyForKey:@"key"]; id def=[specifier propertyForKey:@"default"]; CFPropertyListRef v=CFPreferencesCopyValue((__bridge CFStringRef)key,(__bridge CFStringRef)AFPrefsDomain,kCFPreferencesCurrentUser,kCFPreferencesAnyHost); return v?CFBridgingRelease(v):def; }
- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier { NSString *key=[specifier propertyForKey:@"key"]; CFPreferencesSetValue((__bridge CFStringRef)key,(__bridge CFPropertyListRef)value,(__bridge CFStringRef)AFPrefsDomain,kCFPreferencesCurrentUser,kCFPreferencesAnyHost); CFPreferencesSynchronize((__bridge CFStringRef)AFPrefsDomain,kCFPreferencesCurrentUser,kCFPreferencesAnyHost); CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),(__bridge CFStringRef)AFChangedDarwinNotification,NULL,NULL,YES); }
- (void)showTestPopup { CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),(__bridge CFStringRef)AFTestDarwinNotification,NULL,NULL,YES); }
@end
