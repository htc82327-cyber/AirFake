ARCHS = arm64
TARGET = iphone:clang:latest:15.0
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AirFake
AirFake_FILES = Tweak.xm
AirFake_CFLAGS = -fobjc-arc
AirFake_FRAMEWORKS = UIKit CoreFoundation

INSTALL_TARGET_PROCESSES = SpringBoard Preferences

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += airfakeapp
SUBPROJECTS += airfakeprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
