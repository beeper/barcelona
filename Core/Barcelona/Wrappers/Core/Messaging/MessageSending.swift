//
//  MessageSending.swift
//  Barcelona
//
//  Created by Eric Rabil on 11/2/21.
//

import Foundation
import IMCore

public extension Chat {
    private func markAsRead() {
        if ProcessInfo.processInfo.environment.keys.contains("BARCELONA_GHOST_REPLIES") {
            return
        }
        imChat.markAllMessagesAsRead()
    }
    
    func send(message options: CreatePluginMessage) throws -> Message {
        let message = try options.imMessage(inChat: self.id)
        
        Chat.delegate?.chat(self, willSendMessages: [message], fromCreatePluginMessage: options)
        
        Thread.main.sync {
            markAsRead()
            imChat.send(message)
        }
        
        return Message(messageItem: message._imMessageItem, chatID: imChat.id)
    }
    
    func send(message createMessage: CreateMessage) throws -> Message {
        let message = try createMessage.imMessage(inChat: self.id)
            
        Chat.delegate?.chat(self, willSendMessages: [message], fromCreateMessage: createMessage)
        
        Thread.main.sync {
            markAsRead()
            imChat.send(message)
        }
        
        return Message(messageItem: message._imMessageItem, chatID: imChat.id)
    }
    
    func tapback(_ creation: TapbackCreation) throws -> Message {
        markAsRead()
        let message = try imChat.tapback(guid: creation.message, itemGUID: creation.item, type: creation.type, overridingItemType: nil)
        
        return Message(messageItem: message._imMessageItem, chatID: imChat.id)
    }
}
