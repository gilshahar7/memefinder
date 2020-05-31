ARCHS = arm64 arm64e
export TARGET = iphone:clang:13.2:7.0

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = MEMEFinder

MEMEFinder_FILES = Tweak.x
MEMEFinder_LIBRARIES = activator
MEMEFinder_FRAMEWORKS = WebKit
MEMEFinder_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
