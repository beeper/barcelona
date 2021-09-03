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
