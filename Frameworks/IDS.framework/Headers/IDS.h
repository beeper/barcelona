#import <IDS/ENGroupContextCacheMiddleware.h>
#import <IDS/ENGroupContextDataSource.h>
#import <IDS/ENGroupContextMiddleware.h>
#import <IDS/IDSAccount.h>
#import <IDS/IDSAccountController.h>
#import <IDS/IDSAccountControllerDelegate.h>
#import <IDS/IDSAccountDelegate.h>
#import <IDS/IDSAccountRegistrationDelegate.h>
#import <IDS/IDSAppleCareDaemonResponseListener.h>
#import <IDS/IDSAuthenticationCertificateSignature.h>
#import <IDS/IDSAuthenticationSigningResult.h>
#import <IDS/IDSAutoCleanup.h>
#import <IDS/IDSBaseSocketPairConnectionDelegate.h>
#import <IDS/IDSBatchIDQueryController.h>
#import <IDS/IDSCarrierToken.h>
#import <IDS/IDSCarrierTokenRequestParameters.h>
#import <IDS/IDSConnection.h>
#import <IDS/IDSConnectionDelegate.h>
#import <IDS/IDSConnectionDelegatePrivate.h>
#import <IDS/IDSContinuity.h>
#import <IDS/IDSDaemonController.h>
#import <IDS/IDSDaemonControllerForwarder.h>
#import <IDS/IDSDaemonListener.h>
#import <IDS/IDSDaemonListenerProtocol.h>
#import <IDS/IDSDaemonProtocol.h>
#import <IDS/IDSDaemonProtocolController.h>
#import <IDS/IDSDaemonRequestContext.h>
#import <IDS/IDSDaemonRequestTimer.h>
#import <IDS/IDSDaemonResponseHandler.h>
#import <IDS/IDSDataChannelLinkContext.h>
#import <IDS/IDSDatagramChannel.h>
#import <IDS/IDSDestination-Additions.h>
#import <IDS/IDSDevice.h>
#import <IDS/IDSDeviceConnection.h>
#import <IDS/IDSGroupContextCacheMiddlewareDaemonProtocol.h>
#import <IDS/IDSGroupContextController.h>
#import <IDS/IDSGroupContextControllerContent.h>
#import <IDS/IDSGroupContextControllerDelegate.h>
#import <IDS/IDSGroupContextDaemonProtocol.h>
#import <IDS/IDSGroupContextDataSource.h>
#import <IDS/IDSGroupContextDataSourceDaemonProtocol.h>
#import <IDS/IDSGroupContextNotifyingObserver.h>
#import <IDS/IDSGroupContextNotifyingObserverDelegate.h>
#import <IDS/IDSGroupContextObserverDaemonProtocol.h>
#import <IDS/IDSGroupSession.h>
#import <IDS/IDSGroupSessionUnicastParameter.h>
#import <IDS/IDSHomeKitManager.h>
#import <IDS/IDSIDQueryController.h>
#import <IDS/IDSIDQueryControllerDelegate.h>
#import <IDS/IDSInternalQueueController.h>
#import <IDS/IDSLocalPairingAddPairedDeviceInfo.h>
#import <IDS/IDSLocalPairingIdentityDataErrorPair.h>
#import <IDS/IDSLocalPairingLocalDeviceRecord.h>
#import <IDS/IDSLocalPairingPairedDeviceRecord.h>
#import <IDS/IDSLocalPairingRecord.h>
#import <IDS/IDSLogging.h>
#import <IDS/IDSPairedDeviceManager.h>
#import <IDS/IDSPhoneCertificateVendor.h>
#import <IDS/IDSPhoneSubscription.h>
#import <IDS/IDSPhoneSubscriptionSelector.h>
#import <IDS/IDSQuickRelayFixedTokenAllocator.h>
#import <IDS/IDSQuickSwitchAcknowledgementTracker.h>
#import <IDS/IDSRealTimeEncryptionProxy.h>
#import <IDS/IDSRegistrationControlDaemonResponseListener.h>
#import <IDS/IDSReportiMessageSpamDaemonResponseListener.h>
#import <IDS/IDSService.h>
#import <IDS/IDSServiceAvailabilityController.h>
#import <IDS/IDSServiceContainer.h>
#import <IDS/IDSServiceMonitor.h>
#import <IDS/IDSSession.h>
#import <IDS/IDSSignInController.h>
#import <IDS/IDSSignInControllerAccountDescription.h>
#import <IDS/IDSSignInServiceUserInfo.h>
#import <IDS/IDSSignInServiceUserStatus.h>
#import <IDS/IDSTransactionLogBaseTaskHandler.h>
#import <IDS/IDSTransactionLogDataMessage.h>
#import <IDS/IDSTransactionLogDictionaryMessage.h>
#import <IDS/IDSTransactionLogMessage.h>
#import <IDS/IDSTransactionLogSyncTask.h>
#import <IDS/IDSTransactionLogSyncTaskHandler.h>
#import <IDS/IDSTransactionLogTask.h>
#import <IDS/IDSTransactionLogTaskHandler.h>
#import <IDS/IDSTransactionLogTaskHandlerAccountInfo.h>
#import <IDS/IDSTransactionLogTaskHandlerDelegate.h>
#import <IDS/IDSTransportLog.h>
#import <IDS/IDSXPCConnection.h>
#import <IDS/IDSXPCConnectionRemoteObjectPromise.h>
#import <IDS/IDSXPCConnectionTimeoutProxy.h>
#import <IDS/IDSXPCDaemon.h>
#import <IDS/IDSXPCDaemonClient.h>
#import <IDS/IDSXPCDaemonClientInterface.h>
#import <IDS/IDSXPCDaemonController.h>
#import <IDS/IDSXPCDaemonInterface.h>
#import <IDS/IDSXPCInternalTesting.h>
#import <IDS/IDSXPCInternalTestingInterface.h>
#import <IDS/IDSXPCOpportunistic.h>
#import <IDS/IDSXPCOpportunisticInterface.h>
#import <IDS/IDSXPCPairedDeviceManager.h>
#import <IDS/IDSXPCPairedDeviceManagerInterface.h>
#import <IDS/IDSXPCPairing.h>
#import <IDS/IDSXPCPairingInterface.h>
#import <IDS/IDSXPCRegistration.h>
#import <IDS/IDSXPCRegistrationInterface.h>
#import <IDS/IDSXPCReunionSync.h>
#import <IDS/IDSXPCReunionSyncInterface.h>
#import <IDS/_IDSAccount.h>
#import <IDS/_IDSAccountController.h>
#import <IDS/_IDSBatchIDQueryController.h>
#import <IDS/_IDSCompletionHandler.h>
#import <IDS/_IDSConnection.h>
#import <IDS/_IDSContinuity.h>
#import <IDS/_IDSDataChannelLinkContext.h>
#import <IDS/_IDSDatagramChannel.h>
#import <IDS/_IDSDevice.h>
#import <IDS/_IDSDeviceConnection.h>
#import <IDS/_IDSDeviceConnectionActiveMap.h>
#import <IDS/_IDSGenericCompletionHandler.h>
#import <IDS/_IDSGroupSession.h>
#import <IDS/_IDSIDQueryController.h>
#import <IDS/_IDSPasswordManager.h>
#import <IDS/_IDSRealTimeEncryptionProxy.h>
#import <IDS/_IDSService.h>
#import <IDS/_IDSSession.h>

NSString* IDSCopyIDForPhoneNumber(CFStringRef);
NSString* IDSCopyIDForEmailAddress(CFStringRef);
NSString* IDSCopyIDForBusinessID(CFStringRef);
extern NSString* IDSServiceNameiMessage;
extern NSString* IDSServiceNameSMSRelay;
extern NSString* IDSServiceNameFaceTime;
extern NSString* IDSServiceNameFaceTimeMultiway;
extern NSString* IDSServiceNameFaceTimeMulti;
extern NSString* IDSServiceNameQuickRelayFaceTime;
extern NSString* IDSServiceNameCalling;
extern NSString* IDSServiceNameSpringBoardNotificationSync;
extern NSString* IDSServiceNamePhotoStream;
extern NSString* IDSServiceNameMaps;
extern NSString* IDSServiceNameScreenSharing;
extern NSString* IDSServiceNameMultiplex1;
extern NSString* IDSServiceNameiMessageForBusiness;

//
//     Generated by class-dump 3.5 (64 bit).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2013 by Steve Nygard.
//

#import <Foundation/Foundation.h>

@interface IDSMessageContext: NSObject
- (instancetype) initWithDictionary: (NSDictionary*) dictionary boostContext: (id) boostContext;
@property (nonatomic, readwrite, copy) NSString * outgoingResponseIdentifier;
@property (nonatomic, readwrite, copy) NSString * incomingResponseIdentifier;
@property (nonatomic, readwrite, copy) NSString * serviceIdentifier;
@property (nonatomic, readwrite, copy) NSString * fromID;
@property (nonatomic, readwrite, copy) NSString * originalGUID;
@property (nonatomic, readwrite, copy) NSString * toID;
@property (nonatomic, readwrite, copy) NSString * originalDestinationDevice;
@property (nonatomic, readwrite, copy) NSData * engramGroupID;
@property (nonatomic, readwrite, copy) NSNumber * originalCommand;
@property (nonatomic, readwrite, copy) NSNumber * serverTimestamp;
@property (nonatomic, readwrite, assign) BOOL expectsPeerResponse;
@property (nonatomic, readwrite, assign) BOOL wantsManualAck;
@property (nonatomic, readwrite, assign) BOOL fromServerStorage;
@property (nonatomic, readonly) NSDate * serverReceivedTime;
@property (nonatomic, readonly) NSTimeInterval averageLocalRTT;
//@property (nonatomic, readonly) IDSLocalMessageState localMessageState;
@property (nonatomic, readonly) BOOL deviceBlackedOut;
@property (nonatomic, readonly) NSError * wpConnectionError;
@property (nonatomic, readwrite, copy) NSString * senderCorrelationIdentifier;
@end


@protocol IDSServiceDelegate
@optional
- (void)service:(IDSService *)service account:(IDSAccount *)account incomingMessage:(NSDictionary *)message fromID:(NSString *)fromID context:(IDSMessageContext *)context;
- (void)service:(IDSService *)service account:(IDSAccount *)account incomingData:(NSData *)data fromID:(NSString *)fromID context:(IDSMessageContext *)context;
- (void)service:(IDSService *)service account:(IDSAccount *)account incomingUnhandledProtobuf:(IDSProtobuf *)protobuf fromID:(NSString *)fromID context:(IDSMessageContext *)context;
- (void)service:(IDSService *)service account:(IDSAccount *)account incomingResourceAtURL:(NSURL *)resourceURL fromID:(NSString *)fromID context:(IDSMessageContext *)context;
- (void)service:(IDSService *)service account:(IDSAccount *)account incomingResourceAtURL:(NSURL *)resourceURL metadata:(NSDictionary *)metadata fromID:(NSString *)fromID context:(IDSMessageContext *)context;
- (void)service:(IDSService *)service activeAccountsChanged:(NSSet *)accounts;
- (void)service:(IDSService *)service devicesChanged:(NSArray *)devices;
- (void)service:(IDSService *)service nearbyDevicesChanged:(NSArray *)devices;
- (void)service:(IDSService *)service connectedDevicesChanged:(NSArray *)devices;
- (void)service:(IDSService *)service account:(IDSAccount *)account identifier:(NSString *)identifier didSendWithSuccess:(BOOL)success error:(NSError *)error;
- (void)service:(IDSService *)service account:(IDSAccount *)account identifier:(NSString *)identifier didSendWithSuccess:(BOOL)success error:(NSError *)error context:(IDSMessageContext *)context;
- (void)service:(IDSService *)service account:(IDSAccount *)account identifier:(NSString *)identifier sentBytes:(NSInteger)sentBytes totalBytes:(NSInteger)totalBytes;
- (void)service:(IDSService *)service account:(IDSAccount *)account identifier:(NSString *)identifier hasBeenDeliveredWithContext:(id)context;
- (void)service:(IDSService *)service account:(IDSAccount *)account identifier:(NSString *)identifier fromID:(NSString *)fromID hasBeenDeliveredWithContext:(id)context;
- (void)service:(IDSService *)service account:(IDSAccount *)account inviteReceivedForSession:(IDSSession *)session fromID:(NSString *)fromID;
- (void)service:(IDSService *)service account:(IDSAccount *)account inviteReceivedForSession:(IDSSession *)session fromID:(NSString *)fromID withOptions:(NSDictionary *)inviteOptions;
- (void)service:(IDSService *)service account:(IDSAccount *)account inviteReceivedForSession:(IDSSession *)session fromID:(NSString *)fromID withContext:(NSData *)context;
- (void)service:(IDSService *)service account:(IDSAccount *)account receivedGroupSessionParticipantUpdate:(IDSGroupSessionParticipantUpdate *)groupSessionParticipantUpdate;
- (void)serviceSpaceDidBecomeAvailable:(IDSService *)service;
- (void)serviceAllowedTrafficClassifiersDidReset:(IDSService *)service;
- (void)service:(IDSService *)service didSwitchActivePairedDevice:(IDSDevice *)activePairedDevice acknowledgementBlock:(void (^)(void))acknowledgementBlock;
@end

NS_ASSUME_NONNULL_BEGIN;

NSString *const IDSGlobalLinkAttributeIPFamilyKey;
NSString *const IDSGlobalLinkAttributeCounterKey;
NSString *const IDSGlobalLinkAttributeTransportKey;
NSString *const IDSGlobalLinkAttributeMTUKey;
NSString *const IDSGlobalLinkAttributeRATKey;
NSString *const IDSGlobalLinkAttributeSKEDataKey;
NSString *const IDSGlobalLinkAttributeConnDataKey;
NSString *const IDSGlobalLinkAttributeAcceptDelayKey;
NSString *const IDSGlobalLinkAttributeRelayRemoteAddressKey;
NSString *const IDSGlobalLinkAttributeHMacKey;
NSString *const IDSGlobalLinkAttributeRTTReportKey;
NSString *const IDSGlobalLinkAttributeLinkUUIDKey;
NSString *const IDSGlobalLinkAttributeCapabilityKey;
NSString *const IDSGlobalLinkAttributeDefaultLocalCBUUIDKey;
NSString *const IDSGlobalLinkAttributeDefaultRemoteCBUUIDKey;
NSString *const IDSGlobalLinkAttributeRelaySessionTokenKey;
NSString *const IDSGlobalLinkAttributeRelaySessionKeyKey;
NSString *const IDSGlobalLinkAttributeRelaySessionIDKey;
NSString *const IDSGlobalLinkAttributeGenericDataKey;
NSString *const IDSGlobalLinkAttributeZUDPDataKey;
NSString *const IDSGlobalLinkAttributeRelayServerDegradedKey;

NSString *const IDSQuickRelayServerProviderKey;

NSString *const IDSGlobalLinkOptionLinkIDKey;
NSString *const IDSGlobalLinkOptionLinkIDToQueryKey;
NSString *const IDSGlobalLinkOptionForceRelayKey;
NSString *const IDSGlobalLinkOptionDisallowCellularKey;
NSString *const IDSGlobalLinkOptionDisallowWiFiKey;
NSString *const IDSGlobalLinkOptionPreferCellularForCallSetupKey;
NSString *const IDSGlobalLinkOptionClientTypeKey;
NSString *const IDSGlobalLinkOptionEnableSKEKey;
NSString *const IDSGlobalLinkOptionPreferredAddressFamilyKey;
NSString *const IDSGlobalLinkOptionInviteSentTimeKey;
NSString *const IDSGlobalLinkOptionInviteRecvTimeKey;
NSString *const IDSGlobalLinkOptionUseSecureControlMessageKey;
NSString *const IDSGlobalLinkOptionQRABlockKey;
NSString *const IDSGlobalLinkOptionNewLinkOptionsKey;
NSString *const IDSGlobalLinkOptionQRSessionInfoKey;
NSString *const IDSGlobalLinkOptionSessionInfoRequestTypeKey;
NSString *const IDSGlobalLinkOptionSessionInfoRequestIDKey;
NSString *const IDSGlobalLinkOptionSessionInfoRelayLinkIDKey;
NSString *const IDSGlobalLinkOptionSessionInfoLinkIDToQueryKey;
NSString *const IDSGlobalLinkOptionSessionInfoGenerationCounterKey;
NSString *const IDSGlobalLinkOptionSessionInfoCookieKey;
NSString *const IDSGlobalLinkOptionSessionInfoPublishedStreamsKey;
NSString *const IDSGlobalLinkOptionSessionInfoSubscribedStreamsKey;
NSString *const IDSGlobalLinkOptionSessionInfoPeerPublishedStreamsKey;
NSString *const IDSGlobalLinkOptionSessionInfoPeerSubscribedStreamsKey;
NSString *const IDSGlobalLinkOptionSessionInfoMaxConcurrentStreamsKey;
NSString *const IDSGlobalLinkOptionSessionInfoResponseParticipantsKey;
NSString *const IDSGlobalLinkOptionSessionInfoResponseStreamInfoKey;
NSString *const IDSGlobalLinkOptionSessionInfoRequestBytesSentKey;
NSString *const IDSGlobalLinkOptionSessionInfoResponseBytesReceivedKey;
NSString *const IDSGlobalLinkOptionStatsIdentifierKey;
NSString *const IDSGlobalLinkOptionStatsSentPacketsKey;
NSString *const IDSGlobalLinkOptionStatsReceivedPacketsKey;
NSString *const IDSGlobalLinkOptionStatsServerTimestampKey;
NSString *const IDSGlobalLinkOptionStatsUplinkBWKey;
NSString *const IDSGlobalLinkOptionGenericDataKey;
NSString *const IDSGlobalLinkOptionAdditionalBindingKey;
NSString *const IDSGlobalLinkOptionTestOptionsKey;

/* Incoming message keys */
NSString *const IDSIncomingMessagePushPayloadKey;
NSString *const IDSIncomingMessageDecryptedDataKey;
NSString *const IDSIncomingMessageOriginalEncryptionTypeKey;
NSString *const IDSIncomingMessageEngramEncryptedDataKey;
NSString *const IDSIncomingMessageEngramGroupKey;
NSString *const IDSIncomingMessageShouldShowPeerErrorsKey;

NSString *const IDSSendMessageOptionSkipPayloadCheckKey;
NSString *const IDSSendMessageOptionTopLevelDictionaryKey;
NSString *const IDSSendMessageOptionDataToEncryptKey;
NSString *const IDSSendMessageOptionWantsResponseKey;
NSString *const IDSSendMessageOptionFromIDKey;
NSString *const IDSSendMessageOptionCommandKey;
NSString *const IDSSendMessageOptionWantsDeliveryStatusKey;
NSString *const IDSSendMessageOptionDeliveryStatusContextKey;
NSString *const IDSSendMessageOptionUUIDKey;
NSString *const IDSSendMessageOptionAlternateCallbackIdentifierKey;
NSString *const IDSSendMessageOptionLocalDeliveryKey;
NSString *const IDSSendMessageOptionRequireBluetoothKey;
NSString *const IDSSendMessageOptionRequireLocalWiFiKey;
NSString *const IDSSendMessageOptionDuetKey;
NSString *const IDSSendMessageOptionOpportunisticDuetKey;
NSString *const IDSSendMessageOptionTetheringKey;
NSString *const IDSSendMessageOptionActivityContinuationKey;
NSString *const IDSSendMessageOptionNSURLSessionKey;
NSString *const IDSSendMessageOptionMapTileKey;
NSString *const IDSSendMessageOptionBypassDuetKey;
NSString *const IDSSendMessageOptionFakeMessage;
NSString *const IDSSendMessageOptionNonWakingKey;
NSString *const IDSSendMessageOptionQueueOneIdentifierKey;
NSString *const IDSSendMessageOptionSockPuppetKey;
NSString *const IDSSendMessageOptionDuetIdentifiersOverrideKey;
NSString *const IDSSendMessageOptionEnforceRemoteTimeoutsKey;
NSString *const IDSSendMessageOptionForceEncryptionOffKey;

NSString *const IDSSendMessageOptionRequireAllRegistrationPropertiesKey;
NSString *const IDSSendMessageOptionRequireLackOfRegistrationPropertiesKey;
NSString *const IDSSendMessageOptionInterestingRegistrationPropertiesKey;
NSString *const IDSSendMessageOptionAccessTokenKey;
NSString *const IDSSendMessageOptionHomeKitMessageKey;
NSString *const IDSSendMessageOptionDisableAliasValidationKey;
NSString *const IDSSendMessageOptionSubServiceKey;
NSString *const IDSSendMessageOptionAllowCloudDeliveryKey;
NSString *const IDSSendMessageOptionAlwaysSkipSelfKey;
NSString *const IDSSendMessageOptionNonCloudWakingKey;
NSString *const IDSSendMessageOptionMetricReportIdentifierKey;
NSString *const IDSSendMessageOptionLiveMessageDeliveryKey;



NS_ASSUME_NONNULL_END;
