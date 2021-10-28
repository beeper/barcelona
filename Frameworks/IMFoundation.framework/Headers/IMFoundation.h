#import <IMFoundation/Broadcaster.h>
#import <IMFoundation/IDSSendXPCProtocol.h>
#import <IMFoundation/IMAVDaemonProtocol.h>
#import <IMFoundation/IMAllocTracking.h>
#import <IMFoundation/IMCallMonitor.h>
#import <IMFoundation/IMCapturedInvocationTrampoline.h>
#import <IMFoundation/IMConnectionMonitor.h>
#import <IMFoundation/IMConnectionMonitorDelegate.h>
#import <IMFoundation/IMDelayedInvocationTrampoline.h>
#import <IMFoundation/IMDeviceSupport.h>
#import <IMFoundation/IMDoubleLinkedList.h>
#import <IMFoundation/IMDoubleLinkedListNode.h>
#import <IMFoundation/IMFileCopier.h>
#import <IMFoundation/IMFileCopierDelegate.h>
#import <IMFoundation/IMFileManager.h>
#import <IMFoundation/IMFoundation.h>
#import <IMFoundation/IMIDSLog.h>
#import <IMFoundation/IMInvocationQueue.h>
#import <IMFoundation/IMInvocationTrampoline.h>
#import <IMFoundation/IMLocalObject.h>
#import <IMFoundation/IMLocalObjectInternal.h>
#import <IMFoundation/IMLockdownManager.h>
#import <IMFoundation/IMLogging.h>
#import <IMFoundation/IMMacNotificationCenterManager.h>
#import <IMFoundation/IMManualUpdater.h>
#import <IMFoundation/IMMessageContext.h>
#import <IMFoundation/IMMobileNetworkManager.h>
#import <IMFoundation/IMMockURLResponse.h>
#import <IMFoundation/IMMultiDict.h>
#import <IMFoundation/IMMultiQueue.h>
#import <IMFoundation/IMMultiQueueItem.h>
#import <IMFoundation/IMNetworkAvailability.h>
#import <IMFoundation/IMNetworkConnectionMonitor.h>
#import <IMFoundation/IMNetworkReachability.h>
#import <IMFoundation/IMOrderedMutableDictionary.h>
#import <IMFoundation/IMPair.h>
#import <IMFoundation/IMPerfNSLogProfilerSink.h>
#import <IMFoundation/IMPerfProfiler.h>
#import <IMFoundation/IMPerfProfilerBehavior.h>
#import <IMFoundation/IMPerfProfilerDefaultBehavior.h>
#import <IMFoundation/IMPerfProfilerSink.h>
#import <IMFoundation/IMPerfSinkPair.h>
#import <IMFoundation/IMPingStatistics.h>
#import <IMFoundation/IMPingTest.h>
#import <IMFoundation/IMPowerAssertion.h>
#import <IMFoundation/IMPurgableObject.h>
#import <IMFoundation/IMRGLog.h>
#import <IMFoundation/IMRKMessageResponseManager.h>
#import <IMFoundation/IMRKResponse.h>
#import <IMFoundation/IMReachability.h>
#import <IMFoundation/IMReachabilityDelegate.h>
#import <IMFoundation/IMRemoteObject.h>
#import <IMFoundation/IMRemoteObjectBroadcaster.h>
#import <IMFoundation/IMRemoteObjectCoding.h>
#import <IMFoundation/IMRemoteObjectInternal.h>
#import <IMFoundation/IMRemoteURLConnection.h>
#import <IMFoundation/IMRemoteURLConnectionMockScheduler.h>
#import <IMFoundation/IMScheduledUpdater.h>
#import <IMFoundation/IMSystemMonitor.h>
#import <IMFoundation/IMSystemMonitorListener.h>
#import <IMFoundation/IMSystemProxySettingsFetcher.h>
#import <IMFoundation/IMThreadedInvocationTrampoline.h>
#import <IMFoundation/IMTimer.h>
#import <IMFoundation/IMTimingCollection.h>
#import <IMFoundation/IMURLResponseToPlist.h>
#import <IMFoundation/IMUserDefaults.h>
#import <IMFoundation/IMUserNotification.h>
#import <IMFoundation/IMUserNotificationCenter.h>
#import <IMFoundation/IMWeakObjectCache.h>
#import <IMFoundation/IMWeakReference.h>
#import <IMFoundation/NSArray-FezAdditions.h>
#import <IMFoundation/NSAttributedString-FezAdditions.h>
#import <IMFoundation/NSBundle-FezBundleHelpers.h>
#import <IMFoundation/NSCharacterSet-IMFoundationAdditions.h>
#import <IMFoundation/NSCopying.h>
#import <IMFoundation/NSData-FezAdditions.h>
#import <IMFoundation/NSDictionary-FezAdditions.h>
#import <IMFoundation/NSError-FezAdditions.h>
#import <IMFoundation/NSFastEnumeration.h>
#import <IMFoundation/NSFileManager-FezAdditions.h>
#import <IMFoundation/NSInvocation-IMInvocationQueueAdditions.h>
#import <IMFoundation/NSMutableArray-FezAdditions.h>
#import <IMFoundation/NSMutableAttributedString-FezAdditions.h>
#import <IMFoundation/NSMutableDictionary-IMFoundation_Additions.h>
#import <IMFoundation/NSMutableSet-FezAdditions.h>
#import <IMFoundation/NSMutableString-FezAdditions.h>
#import <IMFoundation/NSNotificationCenter-_IMNotificationCenterAdditions.h>
#import <IMFoundation/NSNumber-FezAdditions.h>
#import <IMFoundation/NSObject-FezAdditions.h>
#import <IMFoundation/NSObject.h>
#import <IMFoundation/NSProtocolChecker-FezAdditions.h>
#import <IMFoundation/NSSet-FezAdditions.h>
#import <IMFoundation/NSString-FezAdditions.h>
#import <IMFoundation/NSThread-_IMThreadBlockSupport.h>
#import <IMFoundation/NSURL-FezAdditions.h>
#import <IMFoundation/NSUserDefaults-SpecificDomainAdditions.h>
#import <IMFoundation/NetworkChangeNotifier.h>
#import <IMFoundation/OSLogHandleManager.h>
#import <IMFoundation/_IMLogFileCompressor.h>
#import <IMFoundation/_IMNotificationObservationHelper.h>
#import <IMFoundation/_IMPingPacketData.h>
#import <IMFoundation/_IMPingStatisticsCollector.h>
#import <IMFoundation/_IMTimingInstance.h>

BOOL IMStringIsPhoneNumber(CFStringRef);
BOOL IMStringIsBusinessID(CFStringRef);
BOOL IMStringIsEmail(CFStringRef);
CFStringRef IMCountryCodeForNumber(CFStringRef);
NSString * IMFormatPhoneNumber(NSString *inputNumber, BOOL allowSpecialCharacters);
NSString * IMFormattedDisplayStringForID(NSString * ID, NSInteger *outType);

#ifndef IMFOUNDATION_CONST

#define IMFOUNDATION_CONST

NSString* const kFZPersonFirstName;
NSString* const kFZPersonLastName;

extern NSString* IMAttachmentCharacterString;
extern NSString* IMBreadcrumbCharacterString;
extern NSString* IMNonBreakingSpaceString;
extern NSString* IMFontFamilyAttributeName;
extern NSString* IMFontSizeAttributeName;
extern NSString* IMItalicAttributeName;
extern NSString* IMBoldAttributeName;
extern NSString* IMUnderlineAttributeName;
extern NSString* IMStrikethroughAttributeName;
extern NSString* IMLinkAttributeName;
extern NSString* IMAddressAttributeName;
extern NSString* IMCalendarEventAttributeName;
extern NSString* IMDataDetectedAttributeName;
extern NSString* IMPhoneNumberAttributeName;
extern NSString* IMMoneyAttributeName;
extern NSString* IMPreformattedAttributeName;
extern NSString* IMForegroundColorAttributeName;
extern NSString* IMBackgroundColorAttributeName;
extern NSString* IMMessageBackgroundColorAttributeName;
extern NSString* IMBaseWritingDirectionAttributeName;
extern NSString* IMUniqueSmileyNumberAttributeName;
extern NSString* IMSmileyLengthAttributeName;
extern NSString* IMMyNameAttributeName;
extern NSString* IMDataDetectorResultAttributeName;
extern NSString* IMMessageForegroundAttributeName;
extern NSString* IMSmileyDescriptionAttributeName;
extern NSString* IMSmileySpeechDescriptionAttributeName;
extern NSString* IMInlineMediaWidthAttributeName;
extern NSString* IMInlineMediaHeightAttributeName;
extern NSString* IMSearchTermAttributeName;
extern NSString* IMReferencedHandleAttributeName;
extern NSString* IMFileTransferGUIDAttributeName;
extern NSString* IMFilenameAttributeName;
extern NSString* IMFileBookmarkAttributeName;
extern NSString* IMMessagePartAttributeName;
extern NSString* IMAnimatedEmojiAttributeName;
extern NSString* IMBreadcrumbTextMarkerAttributeName;
extern NSString* IMBreadcrumbTextOptionFlags;
extern NSString* IMPluginPayloadAttributeName;
extern NSString* IMOneTimeCodeAttributeName;
extern NSString* IMPhotoSharingAttributeName;

typedef uint32_t FZListenerCapabilities;
const FZListenerCapabilities
                kFZListenerCapManageStatus,
                kFZListenerCapBlackholedChatRegistry,
                kFZListenerCapNotifications,
                kFZListenerCapChats,
                kFZListenerCapAppleVC,
                kFZListenerCapAVChatInfo,
                kFZListenerCapAuxInput,
                kFZListenerCapVCInvitations,
                kFZListenerCapAppleLegacyVC,
                kFZListenerCapFileTransfers,
                kFZListenerCapAccounts,
                kFZListenerCapBuddyList,
                kFZListenerCapSendMessages,
                kFZListenerCapMessageHistory,
                kFZListenerCapIDQueries,
                kFZListenerCapChatCountsObserver,
                kFZListenerCapSentMessageObserver,
                kFZListenerCapDatabaseUpdateObserver,
                kFZListenerCapModifyReadState,
                kFZListenerCapAppleAC,
                kFZListenerCapAVObserver,
                kFZListenerCapOnDemandChatRegistry,
                kFZListenerCapTruncatedChatRegistry,
                kFZListenerCapOneTimeCode,
                kFZListenerCapSkipLastMessageLoad;

NSString * JWUUIDPushObjectToString(NSData * data);

typedef NS_ENUM(UInt8, IMChatStyle) {
    IMInstantMessageChatStyle = '-',
    IMGroupChatStyle          = '+',
    IMRoomChatStyle           = '#',
};

void IMComponentsFromChatGUID(NSString *guid, NSString **chatIdentifier, NSString **service, IMChatStyle *style);
size_t IMiMessageMaxFileSizeForUTI(NSString * UTI, BOOL *allowedLargerRepresentation);

#endif
