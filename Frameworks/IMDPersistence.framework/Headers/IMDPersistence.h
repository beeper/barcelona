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

struct IMDSqlOperation {
    
};

struct CSDBSqliteDatabase {
    
};

struct CSDBSqliteDatabase *IMDSharedSqliteDatabase();
void IMDEnsureSharedRecordStoreInitialized();
//NSArray *_IMDSqlOperationGetRowsWithBindingBlock(IMDSqlOperation *, CFStringRef, dispatch_block_t);
//NSArray *_IMDSqlOperationGetRowsForQueryWithBindingBlock(CFStringRef, NSError **, void (^)(id));
void IMDSetIsRunningInDatabaseServerProcess(char);
NSArray* IMDMessageRecordCopyMessagesForAssociatedGUID(CFStringRef);
NSArray* IMDMessageRecordCopyMessagesForRowIDs(NSArray*);
