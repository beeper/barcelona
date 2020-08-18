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

public struct Message: ChatItemRepresentation {
    static func message(withGUID guid: String, on eventLoop: EventLoop) -> EventLoopFuture<Message?> {
        IMMessage.message(withGUID: guid, on: eventLoop).flatMap { message -> EventLoopFuture<Message?> in
            let promise = eventLoop.makePromise(of: Message?.self)
            
            guard let message = message else {
                promise.succeed(nil)
                return promise.futureResult
            }
            
            databasePool.asyncRead { result in
                switch result {
                case .failure(let error):
                    promise.fail(error)
                case .success(let db):
                    do {
                        guard let chatGroupID = try DBReader(pool: databasePool, eventLoop: messageQuerySystem.next()).chatGroupID(forMessageROWID: message.messageID, in: db) else {
                            promise.succeed(nil)
                            return
                        }
                        
                        ERIndeterminateIngestor.ingest(messageLike: message, in: chatGroupID, on: eventLoop).cascade(to: promise)
                    } catch {
                        promise.fail(error)
                    }
                }
            }
            
            return promise.futureResult
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
        
        self.load(item: item, chatGroupID: chatGroupID)
    }
    
    init(_ backing: IMMessageItem, message: IMMessage, items chatItems: [ChatItem], chatGroupID inChatGroupID: String?) {
        guid = message.guid
        chatGroupID = inChatGroupID
        fromMe = message.isFromMe
        time = (backing.time?.timeIntervalSince1970 ?? 0) * 1000
        timeDelivered = (backing.timeDelivered?.timeIntervalSince1970 ?? 0) * 1000
        sender = message.sender.id
        subject = message.subject?.id
        timeRead = (backing.timeRead?.timeIntervalSince1970 ?? 0) * 1000
        timePlayed = (backing.timePlayed?.timeIntervalSince1970 ?? 0) * 1000
        messageSubject = backing.subject
        isSOS = backing.isSOS
        isTypingMessage = backing.isTypingMessage
        isCancelTypingMessage = backing.isCancelTypingMessage()
        isDelivered = backing.isDelivered
        isAudioMessage = backing.isAudioMessage
        items = chatItems
        flags = backing.flags
        
        if let chatGroupID = chatGroupID {
            description = message.description(forPurpose: 0x2, inChat: Registry.sharedInstance.imChat(withGroupID: chatGroupID)!, senderDisplayName: backing._senderHandle()._displayNameWithAbbreviation)
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
}
