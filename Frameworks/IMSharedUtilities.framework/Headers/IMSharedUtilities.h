#import <IMSharedUtilities/CNChangeHistoryEventVisitor.h>
#import <IMSharedUtilities/CNContact-IMCoreAdditions.h>
#import <IMSharedUtilities/FZMessage.h>
#import <IMSharedUtilities/HTMLToSuper_A_Frame.h>
#import <IMSharedUtilities/HTMLToSuper_BODY_Frame.h>
#import <IMSharedUtilities/HTMLToSuper_BR_Frame.h>
#import <IMSharedUtilities/HTMLToSuper_B_Frame.h>
#import <IMSharedUtilities/HTMLToSuper_Default_Frame.h>
#import <IMSharedUtilities/HTMLToSuper_EM_Frame.h>
#import <IMSharedUtilities/HTMLToSuper_FONT_Frame.h>
#import <IMSharedUtilities/HTMLToSuper_I_Frame.h>
#import <IMSharedUtilities/HTMLToSuper_OBJECT_Frame.h>
#import <IMSharedUtilities/HTMLToSuper_SPAN_Frame.h>
#import <IMSharedUtilities/HTMLToSuper_STRIKE_Frame.h>
#import <IMSharedUtilities/HTMLToSuper_STRONG_Frame.h>
#import <IMSharedUtilities/HTMLToSuper_S_Frame.h>
#import <IMSharedUtilities/HTMLToSuper_U_Frame.h>
#import <IMSharedUtilities/IDSServiceDelegate.h>
#import <IMSharedUtilities/IMAKAppleIDAuthenticationController.h>
#import <IMSharedUtilities/IMAnimatedImagePreviewGenerator.h>
#import <IMSharedUtilities/IMAppleStoreHelper.h>
#import <IMSharedUtilities/IMAssociatedMessageItem.h>
#import <IMSharedUtilities/IMAttachmentUtilities.h>
#import <IMSharedUtilities/IMAttributedStringParser.h>
#import <IMSharedUtilities/IMAttributedStringParserContext.h>
#import <IMSharedUtilities/IMAutomaticEventNotificationQueue.h>
#import <IMSharedUtilities/IMBagUtilities.h>
#import <IMSharedUtilities/IMBatteryStatus.h>
#import <IMSharedUtilities/IMBroadcastingKeyValueCollection.h>
#import <IMSharedUtilities/IMBusinessNameManager.h>
#import <IMSharedUtilities/IMCKPadding.h>
#import <IMSharedUtilities/IMCTSMSUtilities.h>
#import <IMSharedUtilities/IMContactCardPreviewGenerator.h>
#import <IMSharedUtilities/IMContactStore.h>
#import <IMSharedUtilities/IMContactStoreChangeHistoryEventsHandler.h>
#import <IMSharedUtilities/IMCoreAutomationNotifications.h>
#import <IMSharedUtilities/IMCoreSpotlightUtilities.h>
#import <IMSharedUtilities/IMDContactStoreChangeHistoryEventsHandler.h>
#import <IMSharedUtilities/IMDSharedUtilitiesPluginPayload.h>
#import <IMSharedUtilities/IMDefaults.h>
#import <IMSharedUtilities/IMDeviceConditions.h>
#import <IMSharedUtilities/IMDeviceUtilities.h>
#import <IMSharedUtilities/IMEventListener.h>
#import <IMSharedUtilities/IMEventListenerList.h>
#import <IMSharedUtilities/IMEventListenerReference.h>
#import <IMSharedUtilities/IMEventListenerResponse.h>
#import <IMSharedUtilities/IMEventNotification.h>
#import <IMSharedUtilities/IMEventNotificationBroadcaster.h>
#import <IMSharedUtilities/IMEventNotificationManager.h>
#import <IMSharedUtilities/IMEventNotificationQueue.h>
#import <IMSharedUtilities/IMEventNotificationQueueDelegate.h>
#import <IMSharedUtilities/IMFeatureFlags.h>
#import <IMSharedUtilities/IMFileTransfer.h>
#import <IMSharedUtilities/IMFromSuperParserContext.h>
#import <IMSharedUtilities/IMGIFUtils.h>
#import <IMSharedUtilities/IMGroupActionItem.h>
#import <IMSharedUtilities/IMGroupBlacklistManager.h>
#import <IMSharedUtilities/IMGroupTitleChangeItem.h>
#import <IMSharedUtilities/IMHTMLToSuperParserContext.h>
#import <IMSharedUtilities/IMIDSUtilities.h>
#import <IMSharedUtilities/IMINInteractionUtilities.h>
#import <IMSharedUtilities/IMImagePreviewGenerator.h>
#import <IMSharedUtilities/IMImageSource.h>
#import <IMSharedUtilities/IMImageUtilities.h>
#import <IMSharedUtilities/IMItem.h>
#import <IMSharedUtilities/IMKeyValueCollection.h>
#import <IMSharedUtilities/IMKeyValueCollectionDictionaryStorage.h>
#import <IMSharedUtilities/IMKeyValueCollectionStorage.h>
#import <IMSharedUtilities/IMKeyValueCollectionUserDefaultsStorage.h>
#import <IMSharedUtilities/IMLocationShareStatusChangeItem.h>
#import <IMSharedUtilities/IMLogDump.h>
#import <IMSharedUtilities/IMMapPreviewGenerator.h>
#import <IMSharedUtilities/IMMeCardSharingStateController.h>
#import <IMSharedUtilities/IMMessageAcknowledgmentStringHelper.h>
#import <IMSharedUtilities/IMMessageActionItem.h>
#import <IMSharedUtilities/IMMessageItem.h>
#import <IMSharedUtilities/IMMessageNotificationController.h>
#import <IMSharedUtilities/IMMessageNotificationTimeManager.h>
#import <IMSharedUtilities/IMMessageNotificationTimer.h>
#import <IMSharedUtilities/IMMetricsCollector.h>
#import <IMSharedUtilities/IMMoviePreviewGenerator.h>
#import <IMSharedUtilities/IMNickname.h>
#import <IMSharedUtilities/IMNicknameAvatar.h>
#import <IMSharedUtilities/IMNicknameAvatarImage.h>
#import <IMSharedUtilities/IMNicknameEncryptionCipherRecordField.h>
#import <IMSharedUtilities/IMNicknameEncryptionFieldTag.h>
#import <IMSharedUtilities/IMNicknameEncryptionHelpers.h>
#import <IMSharedUtilities/IMNicknameEncryptionKey.h>
#import <IMSharedUtilities/IMNicknameEncryptionPlainRecordField.h>
#import <IMSharedUtilities/IMNicknameEncryptionPreKey.h>
#import <IMSharedUtilities/IMNicknameEncryptionRecordTag.h>
#import <IMSharedUtilities/IMNicknameEncryptionTag.h>
#import <IMSharedUtilities/IMNicknameFieldEncryptionKey.h>
#import <IMSharedUtilities/IMNicknameFieldTaggingKey.h>
#import <IMSharedUtilities/IMNicknameRecordTaggingKey.h>
#import <IMSharedUtilities/IMNotificationCenterEventListener.h>
#import <IMSharedUtilities/IMOneTimeCodeUtilities.h>
#import <IMSharedUtilities/IMParticipantChangeItem.h>
#import <IMSharedUtilities/IMPassKitPreviewGenerator.h>
#import <IMSharedUtilities/IMPreviewGenerator.h>
#import <IMSharedUtilities/IMPreviewGeneratorManager.h>
#import <IMSharedUtilities/IMPreviewGeneratorProtocol.h>
#import <IMSharedUtilities/IMRecentItem.h>
#import <IMSharedUtilities/IMRecentItemsList.h>
#import <IMSharedUtilities/IMRemoteObjectCoding.h>
#import <IMSharedUtilities/IMRequirementLogger.h>
#import <IMSharedUtilities/IMRuntimeTest.h>
#import <IMSharedUtilities/IMRuntimeTestCase.h>
#import <IMSharedUtilities/IMRuntimeTestRun.h>
#import <IMSharedUtilities/IMRuntimeTestSuite.h>
#import <IMSharedUtilities/IMRuntimeTestSuiteTestRun.h>
#import <IMSharedUtilities/IMSandboxingUtils.h>
#import <IMSharedUtilities/IMSharedMessage3rdPartySummary.h>
#import <IMSharedUtilities/IMSharedMessageAppSummary.h>
#import <IMSharedUtilities/IMSharedMessageDTSummary.h>
#import <IMSharedUtilities/IMSharedMessageHandwritingSummary.h>
#import <IMSharedUtilities/IMSharedMessagePhotosSummary.h>
#import <IMSharedUtilities/IMSharedMessageRichLinkSummary.h>
#import <IMSharedUtilities/IMSharedMessageSendingUtilities.h>
#import <IMSharedUtilities/IMSharedUtilities.h>
#import <IMSharedUtilities/IMSharedUtilitiesProtoCloudKitEncryptedGroupAction.h>
#import <IMSharedUtilities/IMSharedUtilitiesProtoCloudKitEncryptedGroupTitleChange.h>
#import <IMSharedUtilities/IMSharedUtilitiesProtoCloudKitEncryptedLocationShareStatusChange.h>
#import <IMSharedUtilities/IMSharedUtilitiesProtoCloudKitEncryptedMessage.h>
#import <IMSharedUtilities/IMSharedUtilitiesProtoCloudKitEncryptedMessageAction.h>
#import <IMSharedUtilities/IMSharedUtilitiesProtoCloudKitEncryptedParticipantChange.h>
#import <IMSharedUtilities/IMShellCommandRunner.h>
#import <IMSharedUtilities/IMSingletonOverride.h>
#import <IMSharedUtilities/IMSingletonOverriding.h>
#import <IMSharedUtilities/IMSingletonProxy.h>
#import <IMSharedUtilities/IMSpamFilterHelper.h>
#import <IMSharedUtilities/IMSticker.h>
#import <IMSharedUtilities/IMStickerPack.h>
#import <IMSharedUtilities/IMSuperToPlainParserContext.h>
#import <IMSharedUtilities/IMSuperToSuperSanitizerContext.h>
#import <IMSharedUtilities/IMTUConversationItem.h>
#import <IMSharedUtilities/IMToSuperParserContext.h>
#import <IMSharedUtilities/IMToSuperParserFrame.h>
#import <IMSharedUtilities/IMTranscoderTelemetry.h>
#import <IMSharedUtilities/IMUTITypeInformation.h>
#import <IMSharedUtilities/IMUnarchiverDecoder.h>
#import <IMSharedUtilities/IMUnitTestBundleLoader.h>
#import <IMSharedUtilities/IMUnitTestFrameworkLoader.h>
#import <IMSharedUtilities/IMUnitTestLogger.h>
#import <IMSharedUtilities/IMUnitTestRunner.h>
#import <IMSharedUtilities/IMUserDefaults-IMEngramUtilities.h>
#import <IMSharedUtilities/IMWeakReferenceCollection.h>
#import <IMSharedUtilities/IMXMLParser.h>
#import <IMSharedUtilities/IMXMLParserContext.h>
#import <IMSharedUtilities/IMXMLParserFrame.h>
#import <IMSharedUtilities/IMXMLReparser.h>
#import <IMSharedUtilities/IMXMLReparserContext.h>
#import <IMSharedUtilities/NSArray-IMIDSUtilities.h>
#import <IMSharedUtilities/NSData-IMKeyValueCollectionUserDefaultsStorage.h>
#import <IMSharedUtilities/NSDate-IMCoreAdditions.h>
#import <IMSharedUtilities/NSDictionary-IMSharedUtilitiesAdditions.h>
#import <IMSharedUtilities/NSError-IMSharedUtilitiesAdditions.h>
#import <IMSharedUtilities/NSFileManager-IMSharedUtilities.h>
#import <IMSharedUtilities/NSNumber-IMKeyValueCollectionUserDefaultsStorage.h>
#import <IMSharedUtilities/NSObject-IMTesting.h>
#import <IMSharedUtilities/NSObject.h>
#import <IMSharedUtilities/NSProxy-NSProxyWorkaround.h>
#import <IMSharedUtilities/NSString-IMPathAdditions.h>
#import <IMSharedUtilities/NSURL-IMPathAdditions.h>
#import <IMSharedUtilities/XCTestObservation.h>

extern id _IMAttachmentPersistentPath(NSString* guid, NSURL* url, NSString* mime, CFStringRef utType);
NSAttributedString* IMCreateSuperFormatStringFromPlainTextString(NSString*);
NSSet<Class> *IMExtensionPayloadUnarchivingClasses();

// MARK: - Extension Payload
extern NSString* IMExtensionPayloadBalloonLayoutInfoKey;
extern NSString* IMExtensionPayloadBalloonLiveLayoutInfoKey;
extern NSString* IMExtensionPayloadBalloonLayoutClassKey;
extern NSString* IMExtensionPayloadURLKey;
extern NSString* IMExtensionPayloadDataKey;
extern NSString* IMExtensionPayloadDataFilePathKey;
/// Not my typo, Apple.
extern NSString* IMExtensionPayloadAccessibilityLableKey;
extern NSString* IMExtensionPayloadAppIconKey;
extern NSString* IMExtensionPayloadAppNameKey;
extern NSString* IMExtensionPayloadAdamIDIKey;
extern NSString* IMExtensionPayloadStatusTextKey;
extern NSString* IMExtensionPayloadLocalizedDescriptionTextKey;
extern NSString* IMExtensionPayloadAlternateTextKey;
extern NSString* IMExtensionPayloadUserSessionIdentifier;
// MARK: - Layout Info
extern NSString* IMBalloonLayoutInfoImageTitleKey;
extern NSString* IMBalloonLayoutInfoImageSubTitleKey;
extern NSString* IMBalloonLayoutInfoCaptionKey;
extern NSString* IMBalloonLayoutInfoSubcaptionKey;
extern NSString* IMBalloonLayoutInfoSecondarySubcaptionKey;
extern NSString* IMBalloonLayoutInfoTertiarySubcaptionKey;
// MARK: - Bundle IDs
extern NSString* IMBalloonBundleIdentifierBusiness;

void IMSharedHelperReplaceExtensionPayloadDataWithFilePathForMessage(IMMessageItem*, NSString*);

API_AVAILABLE(macos(10.16), ios(14.0), watchos(7.0))
BOOL IMEnableInlineReply();

extern NSString* IMMentionAttributeName API_AVAILABLE(macos(10.16), ios(14.0), watchos(7.0));
extern NSString* IMMentionConfirmedMention API_AVAILABLE(macos(10.16), ios(14.0), watchos(7.0));
extern NSString* IMMentionAutomaticConfirmedMention API_AVAILABLE(macos(10.16), ios(14.0), watchos(7.0));
extern NSString* IMMentionOverrideRemoveMention API_AVAILABLE(macos(10.16), ios(14.0), watchos(7.0));
extern NSString* IMMentionOriginalTextMention API_AVAILABLE(macos(10.16), ios(14.0), watchos(7.0));
extern NSString* IMMentionPrefixCharacter API_AVAILABLE(macos(10.16), ios(14.0), watchos(7.0));
extern NSString* IMMentionUnconfirmedDirectMention API_AVAILABLE(macos(10.16), ios(14.0), watchos(7.0));

extern NSString* IMGroupPhotoGuidKey API_AVAILABLE(macos(10.16), ios(14.0), watchos(7.0));

API_AVAILABLE(macos(10.16), ios(14.0), watchos(7.0))
NSString* IMMessageCreateThreadIdentifierWithOriginatorGUID(long long index, long long end, long long start, NSString* guid);

API_AVAILABLE(macos(10.16), ios(14.0), watchos(7.0))
NSString* IMMessageCreateAssociatedMessageGUIDFromThreadIdentifier(NSString* identifier);

NSArray<IMItem*> * FZCreateIMMessageItemsFromSerializedArray(NSArray * serialized) NS_RETURNS_RETAINED;

BOOL IMSharedHelperPersonCentricMergingEnabled(void);
