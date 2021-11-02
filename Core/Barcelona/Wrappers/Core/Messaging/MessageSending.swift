//
//  MessageSending.swift
//  Barcelona
//
//  Created by Eric Rabil on 11/2/21.
//

import Foundation
import IMCore

public extension Chat {
    func send(message options: CreatePluginMessage) throws -> Message {
        let message = try options.imMessage(inChat: self.id)
        
        Chat.delegate?.chat(self, willSendMessages: [message], fromCreatePluginMessage: options)
        
        Thread.main.sync {
            imChat.send(message)
        }
        
        return Message(messageItem: message._imMessageItem, chatID: imChat.id)
    }
    
    func send(message createMessage: CreateMessage) throws -> Message {
        let message = try createMessage.imMessage(inChat: self.id)
            
        Chat.delegate?.chat(self, willSendMessages: [message], fromCreateMessage: createMessage)
        
        Thread.main.sync {
            imChat.send(message)
        }
        
        return Message(messageItem: message._imMessageItem, chatID: imChat.id)
    }
    
    func tapback(_ creation: TapbackCreation) throws -> Message {
        let message = try imChat.tapback(guid: creation.message, itemGUID: creation.item, type: creation.type, overridingItemType: nil)
        
        return Message(messageItem: message._imMessageItem, chatID: imChat.id)
    }
}
