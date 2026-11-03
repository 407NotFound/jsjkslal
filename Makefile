THEOS = /opt/theos
export THEOS_PACKAGE_SCHEME = rootless

TARGET := iphone:clang:14.5:14.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = FilzaWallpaper

$(TWEAK_NAME)_FILES = Tweak.x
$(TWEAK_NAME)_FRAMEWORKS = UIKit Foundation
$(TWEAK_NAME)_PRIVATE_FRAMEWORKS =
$(TWEAK_NAME)_CFLAGS = -fobjc-arc -Wno-unused-variable -Wno-deprecated-declarations
$(TWEAK_NAME)_LDFLAGS =

include $(THEOS_MAKE_PATH)/tweak.mk
