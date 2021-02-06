export TARGET=iphone::13.0 #simulator:clang::11.0
export ARCHS = arm64 #x86_64
export DEBUG = 0

# THEOS_DEVICE_IP = 192.168.4.72
# THEOS_DEVICE_PORT = 22

PACKAGE_VERSION ?= 0.0.4.0

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = barcelonad
$(BUNDLE_NAME)_FILES = $(wildcard *.m)
$(BUNDLE_NAME)_CFLAGS = -fobjc-arc
$(BUNDLE_NAME)_DYNAMIC_LIBRARY = 0
$(BUNDLE_NAME)_INSTALL_PATH = /Library/Application Support/Barcelona

include $(THEOS_MAKE_PATH)/bundle.mk

before-all::
	@if [ ! -f "$(THEOS_INCLUDE_PATH)/sys/kern_memorystatus.h" ]; then \
		mkdir -p "$(THEOS_INCLUDE_PATH)/sys"; \
		curl -s -o "$(THEOS_INCLUDE_PATH)/sys/kern_memorystatus.h" -L "http://www.opensource.apple.com/source/xnu/xnu-2782.1.97/bsd/sys/kern_memorystatus.h?txt"; \
	fi

after-barcelonad-stage::
	$(ECHO_NOTHING)$(FAKEROOT) chown root:wheel $(THEOS_STAGING_DIR)/Library/LaunchAgents/com.ericrabil.barcelonad.plist$(ECHO_END)

after-install::
	install.exec "uicache"
