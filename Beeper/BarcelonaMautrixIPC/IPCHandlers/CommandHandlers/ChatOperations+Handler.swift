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
        payload.reply(withResponse: .chats_resolved(IMChatRegistry.shared.allChats.filter { chat in
            chat.lastFinishedMessageDate.timeIntervalSince1970 > min_timestamp
        }.map(\.guid)))
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
        guard let chat = cbChat else {
            return payload.fail(strategy: .chat_not_found)
        }
        
        chat.markMessageAsRead(withID: read_up_to)
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
