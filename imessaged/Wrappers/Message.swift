//
//  Message.swift
//  imcore-rest
//
//  Created by Eric Rabil on 7/24/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import SocialUI
import IMCore
import Vapor

struct BulkMessageRepresentation: Content {
    init(_ messages: [IMMessage], chatGUID forChatGUID: String) {
        self.messages = messages.map {
            MessageRepresentation($0, chatGUID: forChatGUID)
        }
    }
    
    init(_ messages: ArraySlice<IMMessage>, chatGUID forChatGUID: String) {
        self.messages = messages.map {
            MessageRepresentation($0, chatGUID: forChatGUID)
        }
    }
    
    var messages: [MessageRepresentation]
}

struct BulkMessageIDRepresentation: Content {
    var messages: [String]
}

struct MessageRepresentation: ChatItemRepresentation {
    init(_ item: IMItem, transcriptRepresentation: ChatItem, chatGUID: String?) {
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
        
        self.load(item: item, chatGUID: chatGUID)
    }
    
    init(_ backing: IMMessageItem, chatGUID inChatGUID: String?) {
        let message = backing.message()!
        
        guid = message.guid
        chatGUID = inChatGUID
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
        
        if let chatGUID = chatGUID {
            description = message.description(forPurpose: 0x2, inChat: Registry.sharedInstance.chat(withGUID: chatGUID)!, senderDisplayName: backing._senderHandle()._displayNameWithAbbreviation)
        }
        flags = backing.flags
        items = []
        
        if let chatItems = try? backing._newChatItems() {
            chatItems.forEach {
                if let item = $0 as? IMChatItem {
                    guard let chatGUID = chatGUID, let chatItem = wrapChatItem(unknownItem: item, withChatGUID: chatGUID) else { return }
                    self.items.append(chatItem)
                }
            }
        }
        
        self.load(item: backing, chatGUID: inChatGUID)
    }
    
    init(_ message: IMMessage, chatGUID inChatGUID: String?) {
        self.init(message._imMessageItem, chatGUID: inChatGUID)
        
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
    var chatGUID: String?
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
