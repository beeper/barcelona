BUILD_DIR = ./Build

MACOS_DERIVED_DIR = $(BUILD_DIR)/macOS
MACOS_DESTINATION = "generic/platform=macOS,name=Any Mac"

IOS_DERIVED_DIR = $(BUILD_DIR)/iOS
IOS_DESTINATION = "generic/platform=iOS,name=Any iOS Device"

GIT_TAG := $(shell git tag --points-at HEAD)
ifeq ($(GIT_TAG),)
GIT_TAG := $(shell git log -q -n 1 | head -n 1 | cut -f 2 -d ' ')
endif

clean:
	rm -rf barcelona.xcodeproj Build

soft-clean:
	rm -rf barcelona.xcodeproj

init:
	GIT_TAG=${GIT_TAG} vendor/bin/xcodegen generate
	
refresh: init

scheme:
	env NSUnbufferedIO=YES xcodebuild \
		-project barcelona.xcodeproj \
		-scheme "$(SCHEME)" \
		-parallelizeTargets \
		-jobs 8 \
		-destination "$(DESTINATION)" \
		-configuration Release \
		-derivedDataPath $(DERIVED_DIR) \
		-ONLY_ACTIVE_ARCH=NO | xcbeautify --quieter

scheme-macos:
	$(MAKE) scheme DESTINATION=$(MACOS_DESTINATION) DERIVED_DIR=$(MACOS_DERIVED_DIR)

scheme-ios:
	$(MAKE) scheme DESTINATION=$(IOS_DESTINATION) DERIVED_DIR=$(IOS_DERIVED_DIR)

mautrix-macos: refresh
	$(MAKE) scheme-macos SCHEME=barcelona-mautrix-macOS

grapple-macos: refresh
	$(MAKE) scheme-macos SCHEME=grapple-macOS

mautrix-ios: refresh
	$(MAKE) scheme-ios SCHEME=barcelona-mautrix-iOS

grapple-ios: refresh
	$(MAKE) scheme-ios SCHEME=grapple-iOS

ios-stale:
	$(MAKE) scheme-ios SCHEME=ci-ios

ios: refresh ios-stale

macos-stale:
	$(MAKE) scheme-macos SCHEME=ci-macos

macos: refresh macos-stale

all: refresh
	$(MAKE) -j 2 macos-stale ios-stale
