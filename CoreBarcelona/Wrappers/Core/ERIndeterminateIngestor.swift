//
//  ERIndeterminateIngestor.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 8/17/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import os.log
import NIO

private let TranscriptLikeClasses = [
    IMTranscriptChatItem.self,
    IMGroupTitleChangeItem.self,
    IMParticipantChangeItem.self,
    IMGroupTitleChangeChatItem.self,
    IMGroupActionItem.self
]

private let ChatLikeClasses = [
    IMAttachmentMessagePartChatItem.self,
    IMTranscriptPluginChatItem.self,
    IMTextMessagePartChatItem.self,
    IMMessageAcknowledgmentChatItem.self,
    IMAssociatedMessageItem.self,
    IMMessage.self,
    IMMessageItem.self
]

private let ingestor_eventLoop = MultiThreadedEventLoopGroup(numberOfThreads: 5)

private let ingestor_log = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "ERIndeterminateIngestor")

struct ERIndeterminateIngestor {
    public static func ingest(_ object: AnyObject, in chat: String, on eventLoop: EventLoop = ingestor_eventLoop.next()) -> EventLoopFuture<ChatItem?> {
        let promise = eventLoop.makePromise(of: ChatItem?.self)
        
        os_log("Ingesting object %@ in chat %@", String(describing: object), chat, ingestor_log)
        
        if TranscriptLikeClasses.contains(where: { object.isKind(of: $0) }), !ChatLikeClasses.contains(where: { object.isKind(of: $0) }) {
            os_log("Object %@ is transcript-like", String(describing: object), ingestor_log)
            ingest(transcriptLike: object, in: chat, on: eventLoop).cascade(to: promise)
        } else if ChatLikeClasses.contains(where: { object.isKind(of: $0) }) {
            os_log("Object %@ is chat-like", String(describing: object), ingestor_log)
            ingest(chatLike: object, in: chat, on: eventLoop).cascade(to: promise)
        } else {
            os_log("Object %@ is a stub", String(describing: object), ingestor_log)
            promise.succeed(ChatItem(type: .phantom, item: StubChatItemRepresentation(object, chatGroupID: chat)))
        }
        
        return promise.futureResult
    }
    
    public static func ingest(_ objects: [AnyObject], in chat: String, on eventLoop: EventLoop = ingestor_eventLoop.next()) -> EventLoopFuture<[ChatItem]> {
        EventLoopFuture<ChatItem?>.whenAllSucceed(objects.map {
            self.ingest($0, in: chat, on: eventLoop)
        }, on: eventLoop).map {
            $0.compactMap { $0 }
        }
    }
    
    /// Ingests an array of message-like objects and returns wrapped messages
    public static func ingest(messageLike objects: [AnyObject], in chat: String, on eventLoop: EventLoop = ingestor_eventLoop.next()) -> EventLoopFuture<[Message]> {
        EventLoopFuture<Message?>.whenAllSucceed(objects.map {
            ingest(messageLike: $0, in: chat, on: eventLoop)
        }, on: eventLoop).map {
            $0.compactMap { $0 }
        }
    }
    
    /// Ingests a message-like object and returns the wrapped message
    public static func ingest(messageLike object: AnyObject, in chat: String, on eventLoop: EventLoop = ingestor_eventLoop.next()) -> EventLoopFuture<Message?> {
        var messageItem: IMMessageItem!, message: IMMessage!
        
        switch (object) {
            case let item as IMMessageItem:
                messageItem = item
                message = item.message()
            case let item as IMMessage:
                message = item
                messageItem = item._imMessageItem
            default:
                print("Discarding unknown ChatItem \(object)")
                return eventLoop.makeSucceededFuture(nil)
        }
        
        var parsedChatItems: EventLoopFuture<[ChatItem]>!
        
        if let chatItems = messageItem._newChatItems() {
            parsedChatItems = EventLoopFuture<ChatItem?>.whenAllSucceed(chatItems.map {
                ingest($0, in: chat)
            }, on: eventLoop).map {
                $0.compactMap { $0 }
            }
        } else {
            parsedChatItems = eventLoop.makeSucceededFuture([])
        }
        
        return parsedChatItems.map { chatItems in
            Message(messageItem, message: message, items: chatItems, chatGroupID: chat)
        }
    }
    
    /// Ingests and resolves attachment metadata, succeeding with a detailed chatitem
    private static func ingest(attachment item: IMAttachmentMessagePartChatItem, in chat: String, on eventLoop: EventLoop) -> EventLoopFuture<ChatItem?> {
        let promise = eventLoop.makePromise(of: ChatItem?.self)
        
        DBReader(pool: databasePool, eventLoop: eventLoop).attachment(for: item.transferGUID).whenSuccess { transfer in
            var attachment: AttachmentChatItemRepresentation!
            
            if let transfer = transfer {
                attachment = AttachmentChatItemRepresentation(item, metadata: AttachmentRepresentation(transfer.fileTransfer), chatGroupID: chat)
            } else {
                attachment = AttachmentChatItemRepresentation(item, chatGroupID: chat)
            }
            
            insertTapbacks(forChatLikeItem: attachment, on: eventLoop).map {
                ChatItem(type: .attachment, item: $0)
            }.cascade(to: promise)
        }
        
        return promise.futureResult
    }
    
    private static func insertTapbacks<P: ChatItemAcknowledgable>(forChatLikeItem item: P, on eventLoop: EventLoop) -> EventLoopFuture<P> {
        item.tapbacks(on: eventLoop).map {
            var newItem = item
            newItem.acknowledgments = $0.flatMap {
                $0.items.map {
                    $0.item
                }
            }.compactMap {
                guard let item = $0 as? AcknowledgmentChatItemRepresentation else {
                    return nil
                }
                
                return item
            }
            return newItem
        }
    }
    
    private static func ingest(acknowledgable object: AnyObject, in chat: String, on eventLoop: EventLoop) -> EventLoopFuture<ChatItem?> {
        var pending: EventLoopFuture<ChatItem?>
        
        switch (object) {
        case let item as IMAttachmentMessagePartChatItem:
            pending = ingest(attachment: item, in: chat, on: eventLoop)
        case let item as IMTranscriptPluginChatItem:
            pending = insertTapbacks(forChatLikeItem: PluginChatItemRepresentation(item, chatGroupID: chat), on: eventLoop).map {
                ChatItem(type: .plugin, item: $0)
            }
        case let item as IMTextMessagePartChatItem:
            pending = insertTapbacks(forChatLikeItem: TextChatItemRepresentation(item, chatGroupID: chat), on: eventLoop).map {
                ChatItem(type: .text, item: $0)
            }
        default:
            pending = eventLoop.makeSucceededFuture(nil)
        }
        
        return pending
    }
    
    /// Process human-crafted chat items
    private static func ingest(chatLike object: AnyObject, in chat: String, on eventLoop: EventLoop) -> EventLoopFuture<ChatItem?> {
        let promise = eventLoop.makePromise(of: ChatItem?.self)
        
        switch (object) {
        case is IMAttachmentMessagePartChatItem:
            fallthrough
        case is IMTranscriptPluginChatItem:
            fallthrough
        case is IMTextMessagePartChatItem:
            self.ingest(acknowledgable: object, in: chat, on: eventLoop).cascade(to: promise)
        case let item as IMMessageAcknowledgmentChatItem:
            promise.succeed(ChatItem(type: .acknowledgment, item: AcknowledgmentChatItemRepresentation(item, chatGroupID: chat)))
        case is IMAssociatedMessageItem:
            fallthrough
        case is IMMessage:
            fallthrough
        case is IMMessageItem:
            ingest(messageLike: object, in: chat, on: eventLoop).map {
                guard let message = $0 else {
                    return nil
                }
                
                return ChatItem(type: .message, item: message)
            }.cascade(to: promise)
        default:
            print("Discarding unknown ChatItem \(object)")
            promise.succeed(ChatItem(type: .phantom, item: StubChatItemRepresentation(object, chatGroupID: chat)))
        }
        
        return promise.futureResult
    }
    
    /// Processes transcript-related items and wraps them in a message item
    private static func ingest(transcriptLike object: AnyObject, in chat: String, on eventLoop: EventLoop) -> EventLoopFuture<ChatItem?> {
        let promise = eventLoop.makePromise(of: ChatItem?.self)
        
        var imItem: IMItem!
        
        if let item = object as? IMTranscriptChatItem {
            imItem = item._item()
        } else if let item = object as? IMItem {
            imItem = item
        } else {
            promise.succeed(ChatItem(type: .phantom, item: StubChatItemRepresentation(object, chatGroupID: chat)))
            return promise.futureResult
        }
        
        var chatItem: ChatItem? = nil
        
        switch (object) {
        case let item as IMDateChatItem:
            chatItem = ChatItem(type: .date, item: DateTranscriptChatItemRepresentation(item, chatGroupID: chat))
        case let item as IMSenderChatItem:
            chatItem = ChatItem(type: .sender, item: SenderTranscriptChatItemRepresentation(item, chatGroupID: chat))
        case let item as IMParticipantChangeItem:
            chatItem = ChatItem(type: .participantChange, item: ParticipantChangeTranscriptChatItemRepresentation(item, chatGroupID: chat))
        case let item as IMParticipantChangeChatItem:
            chatItem = ChatItem(type: .participantChange, item: ParticipantChangeTranscriptChatItemRepresentation(item, chatGroupID: chat))
        case let item as IMMessageStatusChatItem:
            chatItem = ChatItem(type: .status, item: StatusChatItemRepresentation(item, chatGroupID: chat))
        case let item as IMGroupActionItem:
            chatItem = ChatItem(type: .groupAction, item: GroupActionTranscriptChatItemRepresentation(item, chatGroupID: chat))
        case let item as IMGroupActionChatItem:
            chatItem = ChatItem(type: .groupAction, item: GroupActionTranscriptChatItemRepresentation(item, chatGroupID: chat))
        case let item as IMGroupTitleChangeChatItem:
            chatItem = ChatItem(type: .groupTitle, item: GroupTitleChangeItemRepresentation(item, chatGroupID: chat))
        case let item as IMGroupTitleChangeItem:
            chatItem = ChatItem(type: .groupTitle, item: GroupTitleChangeItemRepresentation(item, chatGroupID: chat))
        case let item as IMTypingChatItem:
            chatItem = ChatItem(type: .typing, item: TypingChatItemRepresentation(item, chatGroupID: chat))
        default:
            break
        }
        
        if let chatItem = chatItem {
            promise.succeed(ChatItem(type: .message, item: Message(imItem, transcriptRepresentation: chatItem, chatGroupID: chat)))
        } else {
            promise.succeed(ChatItem(type: .phantom, item: StubChatItemRepresentation(object, chatGroupID: chat)))
        }
        
        return promise.futureResult
    }
}
