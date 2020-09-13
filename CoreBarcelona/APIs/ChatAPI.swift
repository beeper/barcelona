//
//  ChatAPI.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/5/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import Vapor
import Swime
import IMCore

import os.log

struct CreateChat: Content {
    var participants: [String]
}

struct RenameChat: Content {
    var name: String?
}

struct ChatPropertiesPatch: Content {
    var ignoreAlerts: Bool?
    var readReceipts: Bool?
}

private let log_chatAPI = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "ChatAPI")
private let log_messageAPI = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "MessageAPI")

// MARK: - Chats
public func bindChatAPI(_ app: Application) {
    let chats = app.grouped("chats")
    
    /**
     Get all chats
     */
    chats.get { req -> EventLoopFuture<BulkChatRepresentation> in
        let limit = try? req.query.get(Int.self, at: "limit")
        let after = try? req.query.get(String.self, at: "after")
        
        let chats = IMChatRegistry.shared.allSortedChats(limit: limit, after: after)
        
        return req.eventLoop.makeSucceededFuture(BulkChatRepresentation(chats))
    }
    
    /**
     Create chat
     */
    chats.post { req -> EventLoopFuture<Chat> in
        guard let createChat = try? req.content.decode(CreateChat.self) else { throw Abort(.badRequest) }
        let promise = req.eventLoop.makePromise(of: Chat.self)
        
        DispatchQueue.global(qos: .userInitiated).async {
            let handles = createChat.participants.compactMap {
                Registry.sharedInstance.imHandle(withID: $0)
            }
            
            guard let chat = IMChatRegistry.sharedInstance()!.chat(forIMHandles: handles, displayName: nil, joinedChatsOnly: false, lastAddressedHandle: nil, lastAddressedSIMID: nil) as? IMChat else {
                promise.fail(Abort(.badRequest))
                return
            }
            
            promise.succeed(Chat(chat))
        }
        
        return promise.futureResult
    }
    
    let chat = chats.grouped(IMChatMiddleware).grouped(":\(IMChatResourceKey)")
    
    /**
     Gets a specific chat with its ID
     */
    chat.get { req -> Chat in
        return req.chat
    }
    
    /**
     Re-joins a chat. This doesn't always work, nor well.
     */
    chat.get("join") { req -> Chat in
        req.imChat.join()
        
        return req.chat
    }
    
    /**
     Delete a chat
     */
    chat.delete { req -> Chat in
        if req.imChat.isBusinessChat {
            req.imChat.closeSession()
        }
        
        req.imChat.deleteAllHistory()
        
        if req.imChat.chatStyle == 0x2d && req.imChat.recipient == nil { req.imChat.remove() }
        else if req.imChat.account.service.isLegacyService { req.imChat.leave() }
        
        return req.chat
    }
    
    /**
     Rename a chat
     */
    chat.patch("name") { req -> Chat in
        guard let rename = try? req.content.decode(RenameChat.self) else { throw Abort(.badRequest) }
        
        req.imChat._setDisplayName(rename.name)
        
        return req.chat
    }
    
    chat.post("typing") { req -> HTTPStatus in
        req.chat.startTyping()
        
        return .noContent
    }
    
    chat.delete("typing") { req -> HTTPStatus in
        req.chat.stopTyping()
        
        return .noContent
    }
    
    chat.post("read") { req -> HTTPStatus in
        req.imChat.markAllMessagesAsRead()
        
        if req.imChat.readReceipts {
            IMChatRegistry.shared._chat_sendReadReceipt(forAllMessages: chat)
        }
        
        return .noContent
    }
    
    chat.get("properties") { req -> ChatConfigurationRepresentation in
        req.imChat.properties
    }
    
    chat.patch("properties") { req -> ChatConfigurationRepresentation in
        guard let patch = try? req.content.decode(ChatPropertiesPatch.self) else { throw Abort(.badRequest) }
        
        req.imChat.readReceipts = patch.readReceipts ?? req.imChat.readReceipts
        req.imChat.ignoreAlerts = patch.ignoreAlerts ?? req.imChat.ignoreAlerts
        
        return req.imChat.properties
    }
    
    bindChatMessagesAPI(chat)
    bindParticipantsAPI(chat)
}
