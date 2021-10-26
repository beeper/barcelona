//
//  ChatOperations+Handler.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 8/23/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import Barcelona
import IMCore

extension GetChatsCommand: Runnable {
    public func run(payload: IPCPayload) {
        payload.reply(withCommand: .response(.chats_resolved(IMChatRegistry.shared.allChats.filter { chat in
            guard let lastMessage = chat.lastMessage else {
                return false
            }
            
            return lastMessage.time.timeIntervalSince1970 > self.min_timestamp
        }.map { $0.guid })))
    }
}

extension GetGroupChatInfoCommand: Runnable {
    public func run(payload: IPCPayload) {
        CLInfo("MautrixIPC", "Getting chat with id %@", chat_guid)
        
        guard let chat = blChat else {
            return payload.fail(strategy: .chat_not_found)
        }
        
        payload.respond(.chat_resolved(chat))
    }
}

extension SendReadReceiptCommand: Runnable {
    public func run(payload: IPCPayload) {
        guard let chat = chat else {
            return payload.fail(strategy: .chat_not_found)
        }
        
        chat.markAllMessagesAsRead()
    }
}

extension SendTypingCommand: Runnable {
    public func run(payload: IPCPayload) {
        guard let chat = cbChat else {
            return payload.fail(strategy: .chat_not_found)
        }
        
        chat.setTyping(typing)
    }
}

extension GetGroupChatAvatarCommand: Runnable {
    public func run(payload: IPCPayload) {
        guard let chat = chat, let groupPhotoID = chat.groupPhotoID else {
            return payload.respond(.chat_avatar(nil))
        }
        
        payload.respond(.chat_avatar(BLAttachment(guid: groupPhotoID)))
    }
}
