#import <Foundation/Foundation.h>
#import "IMChat.h"
#import "IMChatItem.h"
#import "IMTranscriptChatItemRules.h"

API_AVAILABLE(macos(10.16), ios(14.0), watchos(7.0))
@interface IMInlineReplyChatItemRules: IMTranscriptChatItemRules
-(IMInlineReplyChatItemRules*) initWithChat:(IMChat*)arg1 threadIdentifier:(NSString*)arg2;
-(BOOL)_supportsContiguousChatItems;
-(void)_chatItemsWithReplyCountsForNewChatItems:(id)arg1 messageItem:(id)arg2;
-(BOOL)_hasEarlierMessagesToLoad;
-(BOOL)_hasRecentMessagesToLoad;
-(NSArray<IMChatItem*>*)_filteredChatItemsForNewChatItems:(NSArray<IMChatItem*>*)arg1;
-(BOOL)_shouldAppendDateForItem:(IMItem*)arg1 previousItem:(IMItem*)arg2;
-(BOOL)_shouldAppendServiceForItem:(IMItem*)arg1 previousItem:(IMItem*)arg2 chatStyle:(id)arg3;
-(BOOL)_shouldShowReportSpamForChat:(IMChat*)arg1 withItems:(NSArray<IMItem*>*)arg2;
-(BOOL)_shouldAppendReplyContextForItem:(IMItem*)arg1 previousItem:(IMItem*)arg2 chatStyle:(id)arg3;
-(BOOL)_shouldAppendReplyCountIfNeeded;
-(NSString*)threadIdentifier;
-(void)setThreadIdentifier:(NSString*)arg1;
-(NSString*)threadOriginatorMessageGUID;
-(void)setThreadOriginatorMessageGUID:(NSString*)arg1;
-(id)threadOriginatorRange;
-(void)setThreadOriginatorRange:(id)arg1;
@end