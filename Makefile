resolve = $(shell cd $(1) 2> /dev/null && pwd -P)

BARCELONA_SRC_DIR ?= $(call resolve,".")

version ?= $(CURRENT_VERSION)
VERSION = $(version)
BUILD_CONFIGURATION ?= Debug

WORKING_DIR := $(call resolve,".")
MACOS_BUILD_DIR := $(WORKING_DIR)/macos_build
MACOS_DESTINATION = "generic/platform=macOS,name=Any Mac"
MACOS_ARCHS = "x86_64 arm64"
MACOS_STAGING_DIR = $(WORKING_DIR)/macos_staging
ARCHIVE_DIR = $(WORKING_DIR)/archive

CURRENT_VERSION := $(shell cd $(BARCELONA_SRC_DIR) && xcrun agvtool what-marketing-version -terse1)

IOS_BUILD_DIR = $(WORKING_DIR)/ios_build
IOS_DESTINATION = generic/platform=iOS,name=Any iOS Device
IOS_ARCHS = arm64
BARCELONA_IOS_DIR ?= $(call resolve,"imessage-rest-ios")
BARCLEONA_XCPROJ = $(BARCELONA_SRC_DIR)/imessage-rest.xcodeproj
BARCELONA_IOS_STAGING = $(BARCELONA_IOS_DIR)/layout
IOS_ARCHIVE_PATH = $(ARCHIVE_DIR)/MyMessage iOS $(VERSION).deb
MACOS_ARCHIVE_PATH = $(ARCHIVE_DIR)/MyMessage macOS $(VERSION).tar.gz

IMESSAGE_XPC_DIR = $(BARCELONA_IOS_STAGING)/Library/Application Support/Barcelona
IMESSAGE_XPC_TARGET = $(IMESSAGE_XPC_DIR)/imessage-rest.xpc
IMESSAGE_APPLICATIONS_DIR = $(BARCELONA_IOS_STAGING)/Applications
IMESSAGE_APP_TARGET = $(IMESSAGE_APPLICATIONS_DIR)/MyMessage for iOS.app
IMESSAGE_APP_SRC = $(IOS_BUILD_DIR)/MyMessage for iOS.app
IMESSAGE_XPC_SRC = $(IOS_BUILD_DIR)/imessage-rest.xpc

xcbuild_scheme = "xcodebuild ARCHS=\"$(4)\" ONLY_ACTIVE_ARCH=NO -scheme \"$(1)\" -project \"$(BARCLEONA_XCPROJ)\" -destination \"$(2)\" -configuration \"$(BUILD_CONFIGURATION)\" CONFIGURATION_BUILD_DIR=\"$(3)\""
xcbuild_ios_scheme = $(call xcbuild_scheme,$(1),$(IOS_DESTINATION),$(IOS_BUILD_DIR),$(IOS_ARCHS))
xcbuild_macos_scheme = $(call xcbuild_scheme,$(1),$(MACOS_DESTINATION),$(MACOS_BUILD_DIR),$(MACOS_ARCHS))

codesign_daemon = "codesign --deep --entitlements \"imessage-rest/imessage-rest.entitlements\" \"$(1)\" -f -s \"Apple Development\""
codesign_mac_daemon = $(call codesign_daemon,"macos_build/$(1)")
codesign_ios_daemon = $(call codesign_daemon,"ios_build/$(1)")

# init:
# 	@eval $$(rm -rf $(MACOS_STAGING_DIR))
# 	@eval $$(mkdir -p $(MACOS_STAGING_DIR) $(ARCHIVE_DIR))

bump-build-version:
	cd $(BARCELONA_SRC_DIR) && xcrun agvtool next-version -all

set-marketing-version:
	cd $(BARCELONA_SRC_DIR) && xcrun agvtool new-marketing-version $(VERSION)

sign-ios:
	@eval $(call codesign_ios_daemon,"imessage-rest.xpc")

xcbuild-ios:
	mkdir -p $(IOS_BUILD_DIR)

	@eval $(call xcbuild_ios_scheme,"imessage-rest")
	@eval $(call xcbuild_ios_scheme,"MyMessage for iOS")

sign-macos:
	@eval $(call codesign_mac_daemon,"MyMessage.app")
	@eval $(call codesign_mac_daemon,"MyMessage.app/Contents/XPCServices/imessage-rest.xpc")
	@eval $(call codesign_mac_daemon,"imessage-rest.xpc")

xcbuild-macos:
	mkdir -p $(MACOS_BUILD_DIR)

	@eval $(call xcbuild_macos_scheme,"imessage-rest")
	@eval $(call xcbuild_macos_scheme,"imessage-rest-mac-controller")

compile-ios-deb:
	rm -rf $(BARCELONA_IOS_DIR)/packages/*

	cd $(BARCELONA_IOS_DIR) && PACKAGE_VERSION=$(VERSION) make package

archive-ios:
	rm -f "$(IOS_ARCHIVE_PATH)"
	mkdir -p $(ARCHIVE_DIR)

	$(eval FIRST_FILE := $(shell ls $(BARCELONA_IOS_DIR)/packages | head -1))
	$(eval PACKAGE_PATH = $(BARCELONA_IOS_DIR)/packages/$(FIRST_FILE))

	cp "$(PACKAGE_PATH)" "$(IOS_ARCHIVE_PATH)"

archive-macos:
	rm -rf $(MACOS_STAGING_DIR)
	mkdir -p $(MACOS_STAGING_DIR) $(ARCHIVE_DIR)

	cp -r "$(MACOS_BUILD_DIR)/MyMessage.app" "$(MACOS_STAGING_DIR)/MyMessage.app"

	cp -r "$(BARCELONA_SRC_DIR)/Staging/" "$(MACOS_STAGING_DIR)/"
	tar -cvzf "$(MACOS_ARCHIVE_PATH)" -C "$(MACOS_STAGING_DIR)" .

install-ios:
	$(MAKE) xcbuild-ios

	cd $(BARCELONA_IOS_DIR) && PACKAGE_VERSION=$(VERSION) make do

ios:
	$(MAKE) xcbuild-ios
	$(MAKE) sign-ios
	$(MAKE) compile-ios-deb
	$(MAKE) archive-ios

macos:
	$(MAKE) xcbuild-macos
	$(MAKE) sign-macos
	$(MAKE) archive-macos

all:
	$(MAKE) ios
	$(MAKE) macos

release:
	$(MAKE) bump-build-version
	$(MAKE) set-marketing-version
	$(MAKE) all