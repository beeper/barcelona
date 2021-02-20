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

struct CSDBSqliteDatabase *IMDSharedSqliteDatabase();
void IMDEnsureSharedRecordStoreInitialized();
//NSArray *_IMDSqlOperationGetRowsWithBindingBlock(IMDSqlOperation *, CFStringRef, dispatch_block_t);
//NSArray *_IMDSqlOperationGetRowsForQueryWithBindingBlock(CFStringRef, NSError **, void (^)(id));
void IMDSetIsRunningInDatabaseServerProcess(char);
NSArray* IMDMessageRecordCopyMessagesForRowIDs(NSArray*);
id IMDMessageRecordCopyMessageForGUID(CFStringRef);
IMItem* IMDCreateIMItemFromIMDMessageRecordRefWithServiceResolve(id, id, id, id, id) CF_RETURNS_RETAINED;
_Nullable CFArrayRef IMDMessageRecordCopyMessagesForGUIDs(id) CF_RETURNS_RETAINED;

//CFArrayRef IMDMessageRecordCopyArrayOfAssociatedMessagesForMessageGUIDFromSender(NSString *, NSString *, NSError **) CF_RETURNS_RETAINED;
//CFArrayRef IMDMessageRecordCopyMessagesForAssociatedGUID(NSString *) CF_RETURNS_RETAINED;
//CFArrayRef IMDMessageRecordCopyMessagesWithChatIdentifiersOnServicesUpToGUIDOrLimit(CFArrayRef, CFArrayRef, CFStringRef, Boolean, Boolean, int64_t) CF_RETURNS_RETAINED;
//CFArrayRef IMDMessageRecordCopyMessagesWithChatIdentifiersOnServicesUpToGUIDOrLimitWithOptionalThreadIdentifier(CFArrayRef, CFArrayRef, CFStringRef, CFStringRef, Boolean, Boolean, int64_t) CF_RETURNS_RETAINED;
