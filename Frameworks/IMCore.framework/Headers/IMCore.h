#import <IMCore/CLLocationManagerDelegate-Protocol.h>
#import <IMCore/FMFSessionDelegate-Protocol.h>
#import <IMCore/IMAccount.h>
#import <IMCore/IMAccountController.h>
#import <IMCore/IMActionsController.h>
#import <IMCore/IMAddressBook.h>
#import <IMCore/IMAggregateAcknowledgmentChatItem.h>
#import <IMCore/IMAggregateMessagePartChatItem.h>
#import <IMCore/IMAnimatedEmojiMessagePartChatItem.h>
#import <IMCore/IMAssociatedMessageChatItem.h>
#import <IMCore/IMAssociatedMessageItem-IMItemsController.h>
#import <IMCore/IMAssociatedStickerChatItem.h>
#import <IMCore/IMAttachment.h>
#import <IMCore/IMAttachmentMessagePartChatItem.h>
#import <IMCore/IMAudioMessageChatItem.h>
#import <IMCore/IMAutomation.h>
#import <IMCore/IMAutomationBatchMessageOperations.h>
#import <IMCore/IMAutomationGroupChat.h>
#import <IMCore/IMAutomationMessageSend.h>
#import <IMCore/IMBalloonApp.h>
#import <IMCore/IMBalloonAppExtension.h>
#import <IMCore/IMBalloonBrowserPlugin.h>
#import <IMCore/IMBalloonPlugin.h>
#import <IMCore/IMBalloonPluginAttributionController.h>
#import <IMCore/IMBalloonPluginController-Protocol.h>
#import <IMCore/IMBalloonPluginDataSource.h>
#import <IMCore/IMBalloonPluginManager.h>
#import <IMCore/IMBlackholeChatItem.h>
#import <IMCore/IMChat.h>
#import <IMCore/IMChatHistoryController.h>
#import <IMCore/IMChatItem.h>
#import <IMCore/IMChatItemRules-Protocol.h>
#import <IMCore/IMChatRegistry.h>
#import <IMCore/IMChatTranscriptItem-Protocol.h>
#import <IMCore/IMChatTranscriptStatusItem-Protocol.h>
#import <IMCore/IMCloudKitAccountNeedsRepairSyncProgress.h>
#import <IMCore/IMCloudKitCloudKitStorageIsFullSyncProgress.h>
#import <IMCore/IMCloudKitDeviceStorageIsFullSyncProgress.h>
#import <IMCore/IMCloudKitErrorProgressTest.h>
#import <IMCore/IMCloudKitEventHandler-Protocol.h>
#import <IMCore/IMCloudKitEventNotificationManager.h>
#import <IMCore/IMCloudKitEventNotificationManagerRuntimeTest.h>
#import <IMCore/IMCloudKitEventNotificationRuntimeTestSuite.h>
#import <IMCore/IMCloudKitHiddenSyncProgress.h>
#import <IMCore/IMCloudKitHookTestSingleton.h>
#import <IMCore/IMCloudKitHooks.h>
#import <IMCore/IMCloudKitKeyRollPendingErrorProgress.h>
#import <IMCore/IMCloudKitMockSyncState.h>
#import <IMCore/IMCloudKitPausedSyncProgress.h>
#import <IMCore/IMCloudKitSyncProgress.h>
#import <IMCore/IMCloudKitSyncProgressIsSyncing.h>
#import <IMCore/IMCloudKitSyncProgressRuntimeTest.h>
#import <IMCore/IMCloudKitSyncProgressRuntimeTestDeleting.h>
#import <IMCore/IMCloudKitSyncProgressRuntimeTestDownloading.h>
#import <IMCore/IMCloudKitSyncProgressRuntimeTestPaused.h>
#import <IMCore/IMCloudKitSyncProgressRuntimeTestPreparing.h>
#import <IMCore/IMCloudKitSyncProgressRuntimeTestUploading.h>
#import <IMCore/IMCloudKitSyncState.h>
#import <IMCore/IMCloudKitSyncStatistics.h>
#import <IMCore/IMCommLimitsPolicyCache.h>
#import <IMCore/IMCore.h>
#import <IMCore/IMCoreAutomationHook.h>
#import <IMCore/IMDDController.h>
#import <IMCore/IMDaemonController.h>
#import <IMCore/IMDaemonListener.h>
#import <IMCore/IMDaemonListenerProtocol-Protocol.h>
#import <IMCore/IMDateChatItem.h>
#import <IMCore/IMDirectlyObservableObject.h>
#import <IMCore/IMEmoteMessageChatItem.h>
#import <IMCore/IMErrorMessagePartChatItem.h>
#import <IMCore/IMExpirableMessageChatItem.h>
#import <IMCore/IMExpressiveSendAsTextChatItem.h>
#import <IMCore/IMFMFSession.h>
#import <IMCore/IMFileTransferCenter.h>
#import <IMCore/IMGroupActionChatItem.h>
#import <IMCore/IMGroupActionItem-IMTranscriptChatItemRules.h>
#import <IMCore/IMGroupTitleChangeChatItem.h>
#import <IMCore/IMGroupTitleChangeItem-IMTranscriptChatItemRules.h>
#import <IMCore/IMGUIDItem.h>
#import <IMCore/IMHandle.h>
#import <IMCore/IMHandleRegistrar.h>
#import <IMCore/IMIDStatusController.h>
#import <IMCore/IMItem-IMChat_Internal.h>
#import <IMCore/IMItemChatContext.h>
#import <IMCore/IMItemsController.h>
#import <IMCore/IMInlineReplyChatItemRules.h>
#import <IMCore/IMInlineReplyController.h>
#import <IMCore/IMLoadMoreChatItem.h>
#import <IMCore/IMLoadMoreRecentChatItem.h>
#import <IMCore/IMLocatingChatItem.h>
#import <IMCore/IMLocationManager-Protocol.h>
#import <IMCore/IMLocationManager.h>
#import <IMCore/IMLocationManagerUtils.h>
#import <IMCore/IMLocationShareActionChatItem.h>
#import <IMCore/IMLocationShareOfferChatItem.h>
#import <IMCore/IMLocationShareStatusChangeItem-IMTranscriptChatItemRules.h>
#import <IMCore/IMMe.h>
#import <IMCore/IMMessage.h>
#import <IMCore/IMMessageAcknowledgmentChatItem.h>
#import <IMCore/IMMessageActionChatItem.h>
#import <IMCore/IMMessageActionItem-IMTranscriptChatItemRules.h>
#import <IMCore/IMMessageAttributionChatItem.h>
#import <IMCore/IMMessageChatItem-Protocol.h>
#import <IMCore/IMMessageChatItem.h>
#import <IMCore/IMMessageEditChatItem.h>
#import <IMCore/IMMessageEffectControlChatItem.h>
#import <IMCore/IMMessageItem-IMChat_Internal.h>
#import <IMCore/IMMessageItemChatContext.h>
#import <IMCore/IMMessagePartChatItem.h>
#import <IMCore/IMMessageStatusChatItem.h>
#import <IMCore/IMNicknameController.h>
#import <IMCore/IMNumberChangedChatItem.h>
#import <IMCore/IMOneTimeCodeAccelerator.h>
#import <IMCore/IMOrderingMetricCollector.h>
#import <IMCore/IMOrderingTools.h>
#import <IMCore/IMParentalControls.h>
#import <IMCore/IMParentalControlsService.h>
#import <IMCore/IMParticipantChangeChatItem.h>
#import <IMCore/IMParticipantChangeItem-IMTranscriptChatItemRules.h>
#import <IMCore/IMPeople.h>
#import <IMCore/IMPeopleCollection.h>
#import <IMCore/IMPerson.h>
#import <IMCore/IMPersonRegistrar.h>
#import <IMCore/IMPluginChatItemProtocol-Protocol.h>
#import <IMCore/IMPluginPayload.h>
#import <IMCore/IMRecentItemsList-FetchUtilities.h>
#import <IMCore/IMRemindersIntegration.h>
#import <IMCore/IMRemoteDaemonProtocol-Protocol.h>
#import <IMCore/IMReportSpamChatItem.h>
#import <IMCore/IMReusableBalloonPluginController-Protocol.h>
#import <IMCore/IMSMSSpamChatItem.h>
#import <IMCore/IMSPIAttachment.h>
#import <IMCore/IMSPIChat.h>
#import <IMCore/IMSPIHandle.h>
#import <IMCore/IMSPIMessage.h>
#import <IMCore/IMSPIRecentEvent.h>
#import <IMCore/IMSPISuggestionsObject.h>
#import <IMCore/IMSendProgress.h>
#import <IMCore/IMSendProgressDelegate-Protocol.h>
#import <IMCore/IMSendProgressRealTimeDataSource.h>
#import <IMCore/IMSendProgressTimeDataSource-Protocol.h>
#import <IMCore/IMSenderChatItem.h>
#import <IMCore/IMService-IMService_GetService.h>
#import <IMCore/IMServiceAgent.h>
#import <IMCore/IMServiceAgentImpl.h>
#import <IMCore/IMServiceChatItem.h>
#import <IMCore/IMServiceImpl.h>
#import <IMCore/IMSimulatedAccount.h>
#import <IMCore/IMSimulatedAccountController.h>
#import <IMCore/IMSimulatedChat.h>
#import <IMCore/IMSimulatedChatDelegate-Protocol.h>
#import <IMCore/IMSimulatedDaemonController.h>
#import <IMCore/IMSimulatedDaemonListener-Protocol.h>
#import <IMCore/IMSuggestionsService.h>
#import <IMCore/IMSystemMonitorListener-Protocol.h>
#import <IMCore/IMTUConversationChatItem.h>
#import <IMCore/IMTUConversationItem-IMTranscriptChatItemRules.h>
#import <IMCore/IMTextMessagePartChatItem.h>
#import <IMCore/IMTimingCollection-IMCoreSetupTimingAdditions.h>
#import <IMCore/IMTranscriptChatItem.h>
#import <IMCore/IMTranscriptChatItemRules.h>
#import <IMCore/IMTranscriptEffectHelper.h>
#import <IMCore/IMTranscriptPluginBreadcrumbChatItem.h>
#import <IMCore/IMTranscriptPluginChatItem.h>
#import <IMCore/IMTranscriptPluginStatusChatItem.h>
#import <IMCore/IMTypingChatItem.h>
#import <IMCore/IMTypingPluginChatItem.h>
#import <IMCore/IMUnreadCountChatItem.h>
#import <IMCore/IMVisibleAssociatedMessageHost-Protocol.h>
#import <IMCore/IMWhitelistController.h>
#import <IMCore/INSpeakable-Protocol.h>
#import <IMCore/Person.h>
#import <IMCore/Presentity.h>
#import <IMCore/TUCallProviderManagerDelegate-Protocol.h>
#import <IMCore/TUConversationManagerDelegate-Protocol.h>
#import <IMCore/_IMBalloonBundleApp.h>
#import <IMCore/_IMBalloonExtensionApp.h>
#import <DataDetectorsCore/DDScannerResult.h>
#import <IMCore/BusinessChat.h>

#ifndef IMCORE_TYPES

#define IMCORE_TYPES

NSString* IMNormalizedPhoneNumberForPhoneNumber(NSString*, NSString*, BOOL);
BOOL IMSPIQueryIMMessageItemsWithGUIDsAndQOS(NSArray<NSString *> *__strong, dispatch_qos_class_t, __strong dispatch_queue_t, __strong void (^)(NSArray*));
BOOL IMSPIQueryMessagesWithGUIDsAndQOS(NSArray<NSString *> *__strong, dispatch_qos_class_t, __strong dispatch_queue_t, __strong void (^)(NSArray*));
DDScannerResult* IMCopyDDScannerResultFromAttributedStringData(NSData*);
BOOL IMCoreSimulatedEnvironmentEnabled();

extern NSString* ABIMHandlesChangedNotification;
extern NSString* IMAVChatInfoNotification;
extern NSString* IMAVChatVideoStillNotification;
extern NSString* IMAccountActivatedNotification;
extern NSString* IMAccountAliasValidationStatusChangedNotification;
extern NSString* IMAccountAliasesChangedNotification;
extern NSString* IMAccountAuthorizationIDChangedNotification;
extern NSString* IMAccountAuthorizationTokenChangedNotification;
extern NSString* IMAccountCapabilitiesChangedNotification;
extern NSString* IMAccountControllerAccountAddedNotification;
extern NSString* IMAccountControllerAccountRemovedNotification;
extern NSString* IMAccountControllerAccountWillBeRemovedNotification;
extern NSString* IMAccountControllerOperationalAccountsChangedNotification;
extern NSString* IMAccountControllerUpdatedNotification;
extern NSString* IMAccountDeactivatedNotification;
extern NSString* IMAccountDisplayNameChangedNotification;
extern NSString* IMAccountGroupsChangedNotification;
extern NSString* IMAccountInvisibilityChangedNotification;
extern NSString* IMAccountLoggedInNotification;
extern NSString* IMAccountLoggedOutNotification;
extern NSString* IMAccountLoginStatusChangedNotification;
extern NSString* IMAccountNoLongerJustLoggedInNotification;
extern NSString* IMAccountPrivacySettingsChangedNotification;
extern NSString* IMAccountProfileChangedNotification;
extern NSString* IMAccountProfileValidationStatusChangedNotification;
extern NSString* IMAccountPropertiesAndPicturesLoadedNotification;
extern NSString* IMAccountRegistrationStatusChangedNotification;
extern NSString* IMAccountSMSRelayPinAlertNotification;
extern NSString* IMAccountSMSRelayPinDismissNotification;
extern NSString* IMAccountSettingsChangedNotification;
extern NSString* IMAccountStatusChangedNotification;
extern NSString* IMAccountStatusInfoChangedNotification;
extern NSString* IMAccountStatusMessageChangedNotification;
extern NSString* IMAccountVettedAliasesChangedNotification;
extern NSString* IMAddressBookChangedNotification;
extern NSString* IMBalloonPluginAttributionChangedNotification;
extern NSString* IMBalloonPluginEnabledStateChangedNotification;
extern NSString* IMBalloonPluginIconsUpdatedNotification;
extern NSString* IMBalloonPluginManagerInstalledAppsChangedNotification;
extern NSString* IMBuddyListSortChangedNotification;
extern NSString* IMBuddyPropertiesChangedDoneNotification;
extern NSString* IMChatConnectivityChangedNotification;
extern NSString* IMChatDidFetchAttachmentsNotification;
extern NSString* IMChatDisplayNameChangedNotification;
extern NSString* IMChatEngroupFinishedUpdatingNotification;
extern NSString* IMChatErrorDidOccurNotification;
extern NSString* IMChatFMFStatusDidChangeNotification;
extern NSString* IMChatIsFilteredChangedNotification;
extern NSString* IMChatItemsDidChangeNotification;
extern NSString* IMChatJoinStateDidChangeNotification;
extern NSString* IMChatLastAddressedHandleChangedNotification;
extern NSString* IMChatLoadRequestDidCompleteNotification;
extern NSString* IMChatMessageDidChangeNotification;
extern NSString* IMChatMessageFailureCountChangedNotification;
extern NSString* IMChatMessageReceivedNotification;
extern NSString* IMChatMessageSendFailedNotification;
extern NSString* IMChatMultiWayStateChangedNotification;
extern NSString* IMChatMultiWayStateChangedRefreshConversationListNotification;
extern NSString* IMChatOverallChatStatusDidChangeNotification;
extern NSString* IMChatParticipantStateDidChangeNotification;
extern NSString* IMChatParticipantsDidChangeNotification;
extern NSString* IMChatPropertiesChangedNotification;
extern NSString* IMChatPurgedAttachmentsDownloadBatchCompleteNotification;
extern NSString* IMChatPurgedAttachmentsDownloadCompleteNotification;
extern NSString* IMChatReceivedDowngradeNotification;
extern NSString* IMChatRecipientDidChangeNotification;
extern NSString* IMChatRecipientReceivedDowngradeNotification;
extern NSString* IMChatRegistryBlackholedChatsExistNotification;
extern NSString* IMChatRegistryDidLoadNotification;
extern NSString* IMChatRegistryDidRegisterChatNotification;
extern NSString* IMChatRegistryDidRemergeChatsNotification;
extern NSString* IMChatRegistryDidUnregisterChatNotification;
extern NSString* IMChatRegistryFailedCountChangedNotification;
extern NSString* IMChatRegistryLastFailedMessageDateChangedNotification;
extern NSString* IMChatRegistryLastMessageLoadedNotification;
extern NSString* IMChatRegistryMessageSentNotification;
extern NSString* IMChatRegistryUnreadCountChangedNotification;
extern NSString* IMChatRegistryWillLoadNotification;
extern NSString* IMChatRegistryWillRemergeChatsNotification;
extern NSString* IMChatRegistryWillUnregisterChatNotification;
extern NSString* IMChatSendingServiceChangedNotification;
extern NSString* IMChatUnreadCountChangedNotification;
extern NSString* IMChatWatermarkDidUpdateNotification;
extern NSString* IMCloudKitAttemptedToDisableiCloudBackupsNotification;
extern NSString* IMCloudKitFetchedRampStateNotification;
extern NSString* IMCloudKitFetchedSyncDebuggingInfoNotification;
extern NSString* IMCloudKitFetchedSyncStatsNotification;
extern NSString* IMCustomStatusMessagesChangedNotification;
extern NSString* IMDaemonConnectionLostNotification;
extern NSString* IMDaemonDidConnectNotification;
extern NSString* IMDaemonDidDisconnectNotification;
extern NSString* IMDaemonDidWillConnectNotification;
extern NSString* IMDaemonWillConnectNotification;
extern NSString* IMDisplayStatusTextNotification;
extern NSString* IMErrorPostedNotification;
extern NSString* IMFMFSessionActiveDeviceChangedNotification;
extern NSString* IMFMFSessionHandleLocationRefreshedNotification;
extern NSString* IMFMFSessionLocationReceivedNotification;
extern NSString* IMFMFSessionRelationshipStatusDidChangeNotification;
extern NSString* IMFileTransferCreatedNotification;
extern NSString* IMFileTransferFinishedNotification;
extern NSString* IMFileTransferRefreshAllNotification;
extern NSString* IMFileTransferRemovedNotification;
extern NSString* IMFileTransferUpdatedNotification;
extern NSString* IMHandleAuthorizationRequestNotification;
extern NSString* IMHandleCapabilitiesChangedNotification;
extern NSString* IMHandleCustomBackgroundColorChangedNotification;
extern NSString* IMHandleCustomFontColorChangedNotification;
extern NSString* IMHandleExtraPropertiesChangedNotification;
extern NSString* IMHandleFeedUpdatedDateChangedNotification;
extern NSString* IMHandleGroupsChangedNotification;
extern NSString* IMHandleIdlePulseNotification;
extern NSString* IMHandleInfoChangedNotification;
extern NSString* IMHandleIsBotChangedNotification;
extern NSString* IMHandleIsBuddyStatusChangedNotification;
extern NSString* IMHandleIsMobileChangedNotification;
extern NSString* IMHandlePictureChangedNotification;
extern NSString* IMHandlePropertiesChangedNotification;
extern NSString* IMHandleRegistrarAddressBookChangedNotification;
extern NSString* IMHandleSortOrderChangedNotification;
extern NSString* IMHandleStatusChangedNotification;
extern NSString* IMHandlesForABPersonChangedNotification;
extern NSString* IMIDStatusControllerUpdatedNotification;
extern NSString* IMLocalObjectDidDisconnectNotification;
extern NSString* IMManagedPreferencesChangedNotification;
extern NSString* IMMeChangedNotification;
extern NSString* IMMeNowPlayingInfoChangedNotification;
extern NSString* IMMePictureChangedNotification;
extern NSString* IMMeStatusChangedNotification;
extern NSString* IMMyStatusChangedNotification;
extern NSString* IMNicknameControllerDidLoadNotification;
extern NSString* IMNicknameDidChangeNotification;
extern NSString* IMNicknamePreferencesDidChangeNotification;
extern NSString* IMPeopleAddedNotification;
extern NSString* IMPeopleChangedNotification;
extern NSString* IMPeopleRemovedNotification;
extern NSString* IMPersonChangedNotification;
extern NSString* IMPersonInfoChangedNotification;
extern NSString* IMPersonStatusChangedNotification;
extern NSString* IMPersonalNicknameDidChangeNotification;
extern NSString* IMPreferredAccountForServiceChangedNotification;
extern NSString* IMRemoteObjectDidDisconnectNotification;
extern NSString* IMSPILastFailedMessageDateChangedNotification;
extern NSString* IMSPIUnreadMessageCountChangedNotification;
extern NSString* IMServiceDefaultsChangedNotification;
extern NSString* IMServiceDidConnectNotification;
extern NSString* IMServiceDidDisconnectNotification;
extern NSString* IMServiceDidReconnectNotification;
extern NSString* IMServiceInitialSyncPerformedNotification;
extern NSString* IMServiceNotificationActiveAccountChangedNotification;
extern NSString* IMServiceStatusChangedNotification;
extern NSString* IMStatusImagesChangedAppearanceNotification;
extern NSString* kFZDaemonLaunchedDistNotification;

API_AVAILABLE(macos(10.16), ios(14.0), watchos(7.0))
NSString* IMCreateThreadIdentifierForMessagePartChatItem(IMMessagePartChatItem* chatItem);

enum {
    IMChatServiceForSendingAvailabilityErrorNone = 0,
    IMChatServiceForSendingAvailabilityErrorTooManyRecipients = 1,
    IMChatServiceForSendingAvailabilityErrorIMessageRequired = 2,
    IMChatServiceForSendingAvailabilityErrorMMSRequired = 3,
    IMChatServiceForSendingAvailabilityErrorNoAvailableServices = 4,
};
typedef int8_t IMChatServiceForSendingAvailabilityError;

void IMChatCalculateServiceForSendingNewComposeMaybeForce
               (NSArray<NSString*> *canonicalIDSAddresses,NSString *senderLastAddressedHandle,
               NSString *senderLastAddressedSIMID,BOOL forceMMS,BOOL hasEmailRecipients,
               BOOL hasCachedQuery,BOOL isDowngraded,BOOL hasHistory,IMService* previousService,
                void(^completion)(BOOL allAddressesiMessageCapable, NSDictionary *perRecipientAvailability, BOOL checkedServer, IMChatServiceForSendingAvailabilityError error));

#endif
