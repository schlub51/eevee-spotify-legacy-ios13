TARGET := iphone:clang:16.5:13.0
INSTALL_TARGET_PROCESSES = Spotify
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = 0Eevee

0Eevee_FILES = Tweak.x
0Eevee_CFLAGS = -fobjc-arc
0Eevee_FRAMEWORKS = Foundation UIKit
0Eevee_LIBRARIES = substrate

include $(THEOS_MAKE_PATH)/tweak.mk
