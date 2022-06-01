//
//  MessageSending.swift
//  Barcelona
//
//  Created by Eric Rabil on 11/2/21.
//

import Foundation
import IMCore

extension Date {
    static func now() -> Date { Date() }
}

extension IMChat {
    /// Refreshes the chat service for sending, runs once per chat.
    /// This is a no-op unless `CBFeatureFlags.refreshChatServices` is enabled.
    func refreshServiceForSendingIfNeeded() {
        guard CBFeatureFlags.refreshChatServices else {
            return
        }
        let hasRefreshed = value(forKey: "_hasRefreshedServiceForSending") as? Bool ?? false
        if hasRefreshed {
            return
        }
        refreshServiceForSending()
    }
}

public extension Chat {
    private func markAsRead() {
        if ProcessInfo.processInfo.environment.keys.contains("BARCELONA_GHOST_REPLIES") {
            return
        }
        imChat.markAllMessagesAsRead()
    }
    
    func sendReturningRaw(message createMessage: CreateMessage) throws -> IMMessage {
        let message = try createMessage.imMessage(inChat: self.id)
            
        Chat.delegate?.chat(self, willSendMessages: [message], fromCreateMessage: createMessage)
        
        imChat.refreshServiceForSendingIfNeeded()
        
        Thread.main.sync {
            markAsRead()
            imChat.send(message)
        }
        
        return message
    }
    
    func send(message options: CreatePluginMessage) throws -> Message {
        let message = try options.imMessage(inChat: self.id)
        
        Chat.delegate?.chat(self, willSendMessages: [message], fromCreatePluginMessage: options)
        
        imChat.refreshServiceForSendingIfNeeded()
        
        Thread.main.sync {
            markAsRead()
            imChat.send(message)
        }
        
        return Message(messageItem: message._imMessageItem, chatID: imChat.id)
    }
    
    func send(message createMessage: CreateMessage) throws -> Message {
        return Message(messageItem: try sendReturningRaw(message: createMessage)._imMessageItem, chatID: imChat.id)
    }
    
    func tapback(_ creation: TapbackCreation) throws -> Message {
        markAsRead()
        let message = try imChat.tapback(guid: creation.message, itemGUID: creation.item, type: creation.type, overridingItemType: nil)
        
        return Message(messageItem: message._imMessageItem, chatID: imChat.id)
    }
}
