//
//  File.swift
//  imcore-rest
//
//  Created by Eric Rabil on 7/24/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import AnyCodable
import IMCore
import Vapor

struct BulkChatItemRepresentation: Content {
    var items: [ChatItem]
}

func wrapChatItem(unknownItem raw: NSObject, withChatGroupID groupID: String) -> ChatItem? {
    let item: NSObject = raw
    
    if item is IMTranscriptChatItem || item is IMGroupTitleChangeItem || item is IMParticipantChangeItem || item is IMGroupTitleChangeChatItem || item is IMGroupActionItem {
        var chatItem: ChatItem? = nil
        
        switch (item) {
        case let item as IMDateChatItem:
            chatItem = ChatItem(type: .date, item: DateTranscriptChatItemRepresentation(item, chatGroupID: groupID))
        case let item as IMSenderChatItem:
            chatItem = ChatItem(type: .sender, item: SenderTranscriptChatItemRepresentation(item, chatGroupID: groupID))
        case let item as IMParticipantChangeItem:
            chatItem = ChatItem(type: .participantChange, item: ParticipantChangeTranscriptChatItemRepresentation(item, chatGroupID: groupID))
        case let item as IMParticipantChangeChatItem:
            chatItem = ChatItem(type: .participantChange, item: ParticipantChangeTranscriptChatItemRepresentation(item, chatGroupID: groupID))
        case let item as IMMessageStatusChatItem:
            chatItem = ChatItem(type: .status, item: StatusChatItemRepresentation(item, chatGroupID: groupID))
        case let item as IMGroupActionItem:
            chatItem = ChatItem(type: .groupAction, item: GroupActionTranscriptChatItemRepresentation(item, chatGroupID: groupID))
        case let item as IMGroupActionChatItem:
            chatItem = ChatItem(type: .groupAction, item: GroupActionTranscriptChatItemRepresentation(item, chatGroupID: groupID))
        case let item as IMGroupTitleChangeChatItem:
            chatItem = ChatItem(type: .groupTitle, item: GroupTitleChangeItemRepresentation(item, chatGroupID: groupID))
        case let item as IMGroupTitleChangeItem:
            chatItem = ChatItem(type: .groupTitle, item: GroupTitleChangeItemRepresentation(item, chatGroupID: groupID))
        case let item as IMTypingChatItem:
            chatItem = ChatItem(type: .typing, item: TypingChatItemRepresentation(item, chatGroupID: groupID))
        default:
            break
        }
        
        if let chatItem = chatItem {
            var imItem: IMItem!
            
            if let item = item as? IMTranscriptChatItem {
                imItem = item._item()
            } else if let item = item as? IMItem {
                imItem = item
            } else {
                fatalError("Got an unexpected IMItem in the transcript parser")
            }
            
            return ChatItem(type: .message, item: Message(imItem, transcriptRepresentation: chatItem, chatGroupID: groupID))
        }
    }
    
    switch (item) {
    case let item as IMAttachmentMessagePartChatItem:
        return ChatItem(type: .attachment, item: AttachmentChatItemRepresentation(item, chatGroupID: groupID))
    case let item as IMTranscriptPluginChatItem:
        return ChatItem(type: .plugin, item: PluginChatItemRepresentation(item, chatGroupID: groupID))
    case let item as IMTextMessagePartChatItem:
        return ChatItem(type: .text, item: TextChatItemRepresentation(item, chatGroupID: groupID))
    case let item as IMMessageAcknowledgmentChatItem:
        return ChatItem(type: .acknowledgment, item: AcknowledgmentChatItemRepresentation(item, chatGroupID: groupID))
    case let item as IMAssociatedMessageItem:
        return ChatItem(type: .message, item: Message(item, chatGroupID: groupID))
    case let item as IMMessage:
        return ChatItem(type: .message, item: Message(item, chatGroupID: groupID))
    case let item as IMMessageItem:
        return ChatItem(type: .message, item: Message(item, chatGroupID: groupID))
    default:
        print("Discarding unknown ChatItem '\(item)'")
        return ChatItem(type: .phantom, item: StubChatItemRepresentation(item, chatGroupID: groupID))
    }
}

func parseArrayOf(chatItems: [NSObject], withGroupID groupID: String) -> [ChatItem] {
     let messages: [ChatItem?] = chatItems.map { item in
         wrapChatItem(unknownItem: item, withChatGroupID: groupID)
     }

     return messages.filter { $0 != nil } as! [ChatItem]
 }
