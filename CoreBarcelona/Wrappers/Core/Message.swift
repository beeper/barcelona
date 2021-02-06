//
//  Message.swift
//  imcore-rest
//
//  Created by Eric Rabil on 7/24/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import NIO

public struct BulkMessageRepresentation: Codable {
    public init(_ messages: [Message]) {
        self.messages = messages
    }
    
    public var messages: [Message]
}

public struct BulkMessageIDRepresentation: Codable {
    public init(messages: [String]) {
        self.messages = messages
    }
    
    public var messages: [String]
}

public extension Array where Element == String {
    func er_chatItems(in chat: String) -> EventLoopFuture<[ChatItem]> {
        IMMessage.messages(withGUIDs: self, on: messageQuerySystem.next())
    }
}

extension Array where Element == Message {
    public var representation: BulkMessageRepresentation {
        BulkMessageRepresentation(self)
    }
}

public struct Message: ChatItemRepresentation {
    static func message(withGUID guid: String, on eventLoop: EventLoop) -> EventLoopFuture<Message?> {
        IMMessage.message(withGUID: guid, on: eventLoop).map {
            guard case .message(let message) = $0 else { return nil }
            return message
        }
    }
    
    /// You can call this when you don't need transcript messages, it can be faster but will not always return all results due to IMCore discarding non-IMMessageItems
    static func dirtyMessages(withGUIDs guids: [String], in chat: String? = nil, on eventLoop: EventLoop = messageQuerySystem.next()) -> EventLoopFuture<[Message]> {
        IMMessage.imMessages(withGUIDs: guids, on: eventLoop).flatMap { messages in
            ERIndeterminateIngestor.ingest(messageLike: messages, in: chat)
        }
    }
    
    static func messages(withGUIDs guids: [String], in chat: String? = nil, on eventLoop: EventLoop = messageQuerySystem.next()) -> EventLoopFuture<[Message]> {
        IMMessage.messages(withGUIDs: guids, in: chat, on: eventLoop).map {
            $0.compactMap {
                guard case .message(let message) = $0 else { return nil }
                return message
            }
        }
    }
    
    public static func associatedMessages(withGUID guid: String, on eventLoop: EventLoop? = nil) -> EventLoopFuture<[Message]> {
        DBReader(pool: databasePool, eventLoop: eventLoop ?? messageQuerySystem.next()).associatedMessages(with: guid)
    }
    
    public static func messages(matching query: String, limit: Int) -> EventLoopFuture<[Message]> {
        DBReader().messages(matching: query, limit: limit)
    }

    init(_ item: IMItem, transcriptRepresentation: ChatItem, chatID: String?) {
        id = item.guid
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
        service = item.service?.service?.id ?? .SMS
        associatedMessageID = item.associatedMessageGUID() as? String
        fileTransferIDs = []
        
        self.load(item: item, chatID: chatID)
    }
    
    init(_ backing: IMMessageItem, message: IMMessage, items chatItems: [ChatItem], chatID inChatChatID: String?) {
        id = message.guid
        chatID = inChatChatID
        fromMe = message.isFromMe
        time = (backing.time?.timeIntervalSince1970 ?? 0) * 1000
        timeDelivered = (backing.timeDelivered?.timeIntervalSince1970 ?? message.timeDelivered?.timeIntervalSince1970 ?? 0) * 1000
        sender = message.sender.id
        subject = message.subject?.id
        timeRead = (backing.timeRead?.timeIntervalSince1970 ?? message.timeRead?.timeIntervalSince1970 ?? 0) * 1000
        timePlayed = (backing.timePlayed?.timeIntervalSince1970 ?? message.timePlayed?.timeIntervalSince1970 ?? 0) * 1000
        messageSubject = backing.subject ?? message.messageSubject?.string
        isSOS = backing.isSOS
        isTypingMessage = backing.isTypingMessage || chatItems.contains {
            if case .typing(_) = $0 { return true }
            return false
        }
        
        isCancelTypingMessage = backing.isCancelTypingMessage()
        isDelivered = backing.isDelivered
        isAudioMessage = backing.isAudioMessage
        items = chatItems
        flags = backing.flags
        service = backing.service.service?.id ?? .SMS
        associatedMessageID = message.associatedMessageGUID ?? backing.associatedMessageGUID() as? String
        fileTransferIDs = message.fileTransferGUIDs
        
        if let chatID = chatID, let chat = IMChat.resolve(withIdentifier: chatID) {
            description = message.description(forPurpose: 0x2, inChat: chat)
        }
        
        self.load(message: message)
        self.load(item: backing, chatID: inChatChatID)
    }
    
    init(_ backing: IMMessageItem, items: [ChatItem], chatID: String?) {
        self.init(backing, message: backing.message()!, items: items, chatID: chatID)
    }
    
    init(_ message: IMMessage, items: [ChatItem], chatID: String?) {
        self.init(message._imMessageItem, message: message, items: items, chatID: chatID)
    }
    
    private mutating func load(message: IMMessage) {
        if #available(iOS 14, macOS 10.16, watchOS 7, *) {
            threadIdentifier = message.threadIdentifier()
            threadOriginator = message.threadOriginator()?.guid
        }
    }
    
    public var id: String
    public var chatID: String?
    public var fromMe: Bool?
    public var time: Double?
    public var sender: String?
    public var subject: String?
    public var timeDelivered: Double
    public var timePlayed: Double
    public var timeRead: Double
    public var messageSubject: String?
    public var isSOS: Bool
    public var isTypingMessage: Bool
    public var isCancelTypingMessage: Bool
    public var isDelivered: Bool
    public var isAudioMessage: Bool
    public var description: String?
    public var flags: UInt64
    public var items: [ChatItem]
    public var service: IMServiceStyle
    public var fileTransferIDs: [String]
    public var associatedMessageID: String?
    public var threadIdentifier: String?
    public var threadOriginator: String?
}
