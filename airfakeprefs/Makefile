include $(THEOS)/makefiles/common.mk
BUNDLE_NAME = AirFakePrefs
AirFakePrefs_FILES = AFPRootListController.m
AirFakePrefs_FRAMEWORKS = UIKit CoreFoundation
AirFakePrefs_PRIVATE_FRAMEWORKS = Preferences
AirFakePrefs_INSTALL_PATH = /Library/PreferenceBundles
AirFakePrefs_CFLAGS = -fobjc-arc
include $(THEOS_MAKE_PATH)/bundle.mk

after-AirFakePrefs-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp $(THEOS_PROJECT_DIR)/airfakeprefs/entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/AirFake.plist$(ECHO_END)
	$(ECHO_NOTHING)cp $(THEOS_PROJECT_DIR)/airfakeprefs/Resources/AirFake.png $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/AirFake.png$(ECHO_END)
