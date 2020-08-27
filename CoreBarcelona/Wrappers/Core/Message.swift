//
//  Message.swift
//  imcore-rest
//
//  Created by Eric Rabil on 7/24/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import Vapor

struct BulkMessageRepresentation: Content {
    init(_ messages: [Message]) {
        self.messages = messages
    }
    
    var messages: [Message]
}

struct BulkMessageIDRepresentation: Content {
    var messages: [String]
}

extension Array where Element == String {
    func er_chatItems(in chat: String) -> EventLoopFuture<[ChatItem]> {
        IMMessage.messages(withGUIDs: self, on: messageQuerySystem.next())
    }
}

extension Array where Element == Message {
    var representation: BulkMessageRepresentation {
        BulkMessageRepresentation(self)
    }
}

public struct Message: ChatItemRepresentation {
    static func message(withGUID guid: String, on eventLoop: EventLoop) -> EventLoopFuture<Message?> {
        IMMessage.message(withGUID: guid, on: eventLoop).map {
            $0?.item as? Message
        }
    }
    
    /// You can call this when you don't need transcript messages, it can be faster but will not always return all results due to IMCore discarding non-IMMessageItems
    static func dirtyMessages(withGUIDs guids: [String], on eventLoop: EventLoop = messageQuerySystem.next()) -> EventLoopFuture<[Message]> {
        IMMessage.imMessages(withGUIDs: guids, on: eventLoop).flatMap {
            ERIndeterminateIngestor.ingest(messageLike: $0)
        }
    }
    
    static func messages(withGUIDs guids: [String], on eventLoop: EventLoop = messageQuerySystem.next()) -> EventLoopFuture<[Message]> {
        IMMessage.messages(withGUIDs: guids, on: eventLoop).map {
            $0.compactMap {
                $0.item as? Message
            }
        }
    }

    init(_ item: IMItem, transcriptRepresentation: ChatItem, chatGroupID: String?) {
        guid = item.guid
        fromMe = item.isFromMe
        time = item.time!.timeIntervalSince1970 * 1000
        timeDelivered = 0
        timeRead = 0
        timePlayed = 0
        subject = nil
        isSOS = false
        isTypingMessage = false
        isCancelTypingMessage = false
        isDelivered = true
        isAudioMessage = false
        sender = item.sender
        flags = 0x5
        items = [transcriptRepresentation]
        service = item.service ?? "iMessage"
        
        self.load(item: item, chatGroupID: chatGroupID)
    }
    
    init(_ backing: IMMessageItem, message: IMMessage, items chatItems: [ChatItem], chatGroupID inChatGroupID: String?) {
        guid = message.guid
        chatGroupID = inChatGroupID
        fromMe = message.isFromMe
        time = (backing.time?.timeIntervalSince1970 ?? 0) * 1000
        timeDelivered = (backing.timeDelivered?.timeIntervalSince1970 ?? message.timeDelivered?.timeIntervalSince1970 ?? 0) * 1000
        sender = message.sender.id
        subject = message.subject?.id
        timeRead = (backing.timeRead?.timeIntervalSince1970 ?? message.timeRead?.timeIntervalSince1970 ?? 0) * 1000
        timePlayed = (backing.timePlayed?.timeIntervalSince1970 ?? message.timePlayed?.timeIntervalSince1970 ?? 0) * 1000
        messageSubject = backing.subject
        isSOS = backing.isSOS
        isTypingMessage = backing.isTypingMessage || chatItems.contains {
            $0.type == .typing
        }
        
        isCancelTypingMessage = backing.isCancelTypingMessage()
        isDelivered = backing.isDelivered
        isAudioMessage = backing.isAudioMessage
        items = chatItems
        flags = backing.flags
        service = backing.service
        
        if let chatGroupID = chatGroupID, let senderID = (backing.sender() ?? message.sender?.id), let senderHandle = Registry.sharedInstance.imHandle(withID: senderID), let chat = Registry.sharedInstance.imChat(withGroupID: chatGroupID) {
            description = message.description(forPurpose: 0x2, inChat: chat, senderDisplayName: senderHandle._displayNameWithAbbreviation)
        }
        
        self.load(item: backing, chatGroupID: inChatGroupID)
    }
    
    init(_ backing: IMMessageItem, items: [ChatItem], chatGroupID: String?) {
        self.init(backing, message: backing.message()!, items: items, chatGroupID: chatGroupID)
    }
    
    init(_ message: IMMessage, items: [ChatItem], chatGroupID: String?) {
        self.init(message._imMessageItem, items: items, chatGroupID: chatGroupID)
        
        timeRead = (message.timeRead?.timeIntervalSince1970 ?? 0) * 1000
        timeDelivered = (message.timeDelivered?.timeIntervalSince1970 ?? 0) * 1000
        timePlayed = (message.timePlayed?.timeIntervalSince1970 ?? 0) * 1000
        isDelivered = message.isDelivered
        isAudioMessage = message.isAudioMessage
        isSOS = message.isSOS
        messageSubject = message.messageSubject?.string
        sender = message.sender?.id
    }
    
    var guid: String?
    var chatGroupID: String?
    var fromMe: Bool?
    var time: Double?
    var sender: String?
    var subject: String?
    var timeDelivered: Double
    var timePlayed: Double
    var timeRead: Double
    var messageSubject: String?
    var isSOS: Bool
    var isTypingMessage: Bool
    var isCancelTypingMessage: Bool
    var isDelivered: Bool
    var isAudioMessage: Bool
    var description: String?
    var flags: UInt64
    var items: [ChatItem]
    var service: String
}
