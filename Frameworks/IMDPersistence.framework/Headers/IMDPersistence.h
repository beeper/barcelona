#import <IMDPersistence/IMAbstractDatabaseArchiver.h>
#import <IMDPersistence/IMAbstractDatabaseTrimmer.h>
#import <IMDPersistence/IMDAbstractDatabaseDowngrader.h>
#import <IMDPersistence/IMDCNAliasResolver.h>
#import <IMDPersistence/IMDCNPersonAliasResolver.h>
#import <IMDPersistence/IMDCoreSpotlightBaseIndexer.h>
#import <IMDPersistence/IMDCoreSpotlightChatParticipant.h>
#import <IMDPersistence/IMDCoreSpotlightContactCache.h>
#import <IMDPersistence/IMDCoreSpotlightDispatchObject.h>
#import <IMDPersistence/IMDCoreSpotlightIndexer.h>
#import <IMDPersistence/IMDCoreSpotlightManager.h>
#import <IMDPersistence/IMDCoreSpotlightMessageAttachmentIndexer.h>
#import <IMDPersistence/IMDCoreSpotlightMessageBalloonPluginIndexer.h>
#import <IMDPersistence/IMDCoreSpotlightMessageBodyIndexer.h>
#import <IMDPersistence/IMDCoreSpotlightMessageDataDetectorsIndexer.h>
#import <IMDPersistence/IMDCoreSpotlightMessageMetadataIndexer.h>
#import <IMDPersistence/IMDCoreSpotlightMessageSubjectIndexer.h>
#import <IMDPersistence/IMDCoreSpotlightRecipientIndexer.h>
#import <IMDPersistence/IMDDatabaseDowngradeHelper.h>
#import <IMDPersistence/IMDHistoryAppKitToSuperParserContext.h>
#import <IMDPersistence/IMDHistoryAttachment.h>
#import <IMDPersistence/IMDHistoryHandle.h>
#import <IMDPersistence/IMDHistoryImporter.h>
#import <IMDPersistence/IMDHistoryMessage.h>
#import <IMDPersistence/IMDHistoryUnarchiver.h>
#import <IMDPersistence/IMDMessageAutomaticHistoryDeletion.h>
#import <IMDPersistence/IMDNotificationsController.h>
#import <IMDPersistence/IMDPersistence.h>
#import <IMDPersistence/IMDPersistentAttachmentController.h>
#import <IMDPersistence/IMDSqlQuery.h>
#import <IMDPersistence/IMDSqlSelectQuery.h>
#import <IMDPersistence/IMDSuggestions.h>
#import <IMDPersistence/IMDTaskProgress.h>
#import <IMDPersistence/IMDWhitetailToCoralDowngradeHelper.h>
#import <IMDPersistence/IMDWhitetailToCoralDowngrader.h>
#import <IMDPersistence/IMDatabaseAnonymizer.h>
#import <IMDPersistence/IMTrimDatabaseToDays.h>
#import <IMDPersistence/IMTrimDatabaseToMessageCount.h>
#import <IMDPersistence/NSCoding.h>
#import <IMDPersistence/NSObject.h>
#import <IMDPersistence/SGMessagesSuggestionsServiceDelegate.h>
#import <IMSharedUtilities/IMItem.h>

struct IMDSqlOperation {
    
};

struct CSDBSqliteDatabase {
    
};

CFArrayRef IMDAttachmentRecordCopyPurgedAttachmentsForChatIdentifiersOnServices(CFArrayRef chatIdentifiers, CFArrayRef services, NSInteger limit) CF_RETURNS_RETAINED;

CFStringRef IMDMessageRecordCopyGUID(CFAllocatorRef, IMDMessageRecordRef);

struct CSDBSqliteDatabase *IMDSharedSqliteDatabase();
void IMDEnsureSharedRecordStoreInitialized();
//NSArray *_IMDSqlOperationGetRowsWithBindingBlock(IMDSqlOperation *, CFStringRef, dispatch_block_t);
//NSArray *_IMDSqlOperationGetRowsForQueryWithBindingBlock(CFStringRef, NSError **, void (^)(id));
void IMDSetIsRunningInDatabaseServerProcess(char);
BOOL IMDIsRunningInDatabaseServerProcess(void);

typedef struct _IMDChatRecordStruct *IMDChatRecordRef;
typedef struct _IMDMessageRecordStruct *IMDMessageRecordRef;

NSArray* IMDMessageRecordCopyMessagesForRowIDs(NSArray*);

IMItem * IMDCreateIMItemFromIMDMessageRecordRefWithServiceResolve(id messageRecord, NSString * inputHandleString, BOOL useAttachmentCache, NSString *(^serviceResolve)(NSString *account, NSString *serviceName)) API_DEPRECATED("", macos(10.0,12.0), ios(3.0,15.0),watchos(1.0,8.0)) NS_RETURNS_RETAINED;

IMItem * IMDCreateIMItemFromIMDMessageRecordRefWithAccountLookup(id messageRecord, NSString * inputHandleString, BOOL useAttachmentCache, NSString *(^accountLookup)(NSString *account, NSString *serviceName)) NS_RETURNS_RETAINED API_AVAILABLE(macos(12.0), ios(15.0), watchos(8.0));

_Nullable CFArrayRef IMDMessageRecordCopyMessagesForGUIDs(id) CF_RETURNS_RETAINED;
id IMDAttachmentRecordCopyAttachmentForGUID(CFStringRef) CF_RETURNS_RETAINED;

int64_t IMDMessageRecordGetIndentifierForMessageWithGUID(CFStringRef guid);
IMDChatRecordRef IMDChatRecordCopyChatForMessageID(int64_t messageID) CF_RETURNS_RETAINED;
int64_t IMDChatRecordCachedUnreadCount(IMDChatRecordRef chat);
CFStringRef IMDChatRecordCopyGUID(CFAllocatorRef allocator, IMDChatRecordRef chat) CF_RETURNS_RETAINED;
IMDMessageRecordRef IMDMessageRecordCopyMessageForGUID(CFStringRef guid) CF_RETURNS_RETAINED;
int64_t IMDMessageRecordGetIdentifier(IMDMessageRecordRef message);

//CFArrayRef IMDMessageRecordCopyArrayOfAssociatedMessagesForMessageGUIDFromSender(NSString *, NSString *, NSError **) CF_RETURNS_RETAINED;
//CFArrayRef IMDMessageRecordCopyMessagesForAssociatedGUID(NSString *) CF_RETURNS_RETAINED;
//CFArrayRef IMDMessageRecordCopyMessagesWithChatIdentifiersOnServicesUpToGUIDOrLimit(CFArrayRef, CFArrayRef, CFStringRef, Boolean, Boolean, int64_t) CF_RETURNS_RETAINED;
//CFArrayRef IMDMessageRecordCopyMessagesWithChatIdentifiersOnServicesUpToGUIDOrLimitWithOptionalThreadIdentifier(CFArrayRef, CFArrayRef, CFStringRef, CFStringRef, Boolean, Boolean, int64_t) CF_RETURNS_RETAINED;

typedef struct _IMDChatRecordStruct *IMDChatRecordRef;
IMDChatRecordRef IMDChatRecordCopyChatForMessageID(int64_t messageID) CF_RETURNS_RETAINED;
CFStringRef IMDChatRecordCopyGUID(CFAllocatorRef allocator, IMDChatRecordRef chat) CF_RETURNS_RETAINED;
