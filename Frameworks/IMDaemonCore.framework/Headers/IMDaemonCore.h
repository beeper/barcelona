#import <Foundation/Foundation.h>

@class IMFileTransfer, IMMessageItem;

typedef struct _IMDAttachmentRecordStruct *IMDAttachmentRecordRef;

IMFileTransfer *IMFileTransferFromIMDAttachmentRecordRef(IMDAttachmentRecordRef attachmentRecord) NS_RETURNS_RETAINED;

NS_ASSUME_NONNULL_BEGIN

@interface IMDCKAttachmentSyncController : NSObject
+(instancetype)sharedInstance;

typedef void (^IMAttachmentSyncPerTransferProgressBlock)(IMFileTransfer *transfer, float percentComplete, BOOL complete, NSError * _Nullable error);
typedef void (^IMAttachmentSyncFetchOperationCompletionBlock)(NSError * _Nullable error, NSArray<IMFileTransfer *> *failedTransfers);

- (void) fetchAttachmentDataForTransfers:(NSArray *)transfers
                             highQuality:(BOOL)highQuality
               useNonHSA2ManateeDatabase:(BOOL)useNonHSA2ManateeDatabase
                     perTransferProgress:(IMAttachmentSyncPerTransferProgressBlock)perTransferProgress
                              completion:(IMAttachmentSyncFetchOperationCompletionBlock)completion;

@end

@interface IMDMessageStore: NSObject
+(instancetype)sharedInstance;
- (IMMessageItem *) storeMessage:(IMMessageItem *)message forceReplace:(BOOL)force modifyError:(BOOL)modifyError modifyFlags:(BOOL)modifyFlags flagMask:(uint64_t)flagMask updateMessageCache:(BOOL)updateMessageCache calculateUnreadCount:(BOOL)calculateUnreadCount;
- (IMMessageItem *) storeMessage:(IMMessageItem *)message forceReplace:(BOOL)force modifyError:(BOOL)modifyError modifyFlags:(BOOL)modifyFlags flagMask:(uint64_t)flagMask;
@end

NS_ASSUME_NONNULL_END
