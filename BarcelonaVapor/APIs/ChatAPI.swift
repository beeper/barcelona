//
//  ChatAPI.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/5/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import CoreBarcelona
import Vapor
import Swime
import IMCore
import NIO

import os.log

struct CreateChat: Content {
    var participants: [String]
    var displayName: String?
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
public func bindChatAPI(_ app: RoutesBuilder) {
    let chats = app.grouped("chats")
    
    let readableChats = chats.grouped(TokenGrant.readChats)
    let writableChats = chats.grouped(TokenGrant.writeChats)
    let messageSending = chats.grouped(TokenGrant.writeMessages)
    
    /**
     Get all chats
     */
    readableChats.get { req -> BulkChatRepresentation in
        return BulkChatRepresentation(IMChatRegistry.shared.allSortedChats())
    }
    
    messageSending.grouped("bulk").post("message") { req -> EventLoopFuture<BulkMessageRepresentation> in
        guard let creation = try? req.content.decode(CreateMessage.self), let chatIDs = try? req.query.get([String].self, at: "chats") else {
            throw Abort(.badRequest)
        }
        
        let chats = Chat.resolve(withIdentifiers: chatIDs)
        
        return EventLoopFuture<BulkMessageRepresentation>.whenAllSucceed(chats.map { chat -> EventLoopFuture<BulkMessageRepresentation> in
            chat.send(message: creation)
        }, on: req.eventLoop).map {
            BulkMessageRepresentation($0.reduce(into: [Message]()) { accumulator, bulk in
                accumulator.append(contentsOf: bulk.messages)
            })
        }
    }
    
    messageSending.grouped("bulk").post("plugin") { req -> EventLoopFuture<BulkMessageRepresentation> in
        guard let creation = try? req.content.decode(CreatePluginMessage.self), let chatIDs = try? req.query.get([String].self, at: "chats") else {
            throw Abort(.badRequest)
        }
        
        let chats = Chat.resolve(withIdentifiers: chatIDs)
        
        return EventLoopFuture<BulkMessageRepresentation>.whenAllSucceed(chats.map { chat -> EventLoopFuture<BulkMessageRepresentation> in
            chat.send(message: creation)
        }, on: req.eventLoop).map {
            BulkMessageRepresentation($0.reduce(into: [Message]()) { accumulator, bulk in
                accumulator.append(contentsOf: bulk.messages)
            })
        }
    }
    
    /**
     Create chat
     */
    writableChats.post { req -> EventLoopFuture<Chat> in
        guard let createChat = try? req.content.decode(CreateChat.self) else { throw Abort(.badRequest) }
        let promise = req.eventLoop.makePromise(of: Chat.self)
        
        DispatchQueue.main.async {
            let handles = createChat.participants.compactMap {
                Registry.sharedInstance.imHandle(withID: $0)
            }
            
            let newGUID = NSString.stringGUID()
            
            guard let chat = IMChat()?._init(withGUID: newGUID, account: handles.last!.account, style: ChatStyle.group.rawValue, roomName: nil, displayName: createChat.displayName, lastAddressedHandle: nil, lastAddressedSIMID: nil, items: nil, participants: handles, isFiltered: true, hasHadSuccessfulQuery: false) else {
                promise.fail(Abort(.badRequest))
                return
            }
            
            chat._setupObservation()
            
            IMChatRegistry.sharedInstance()!._registerChat(chat, isIncoming: false, guid: newGUID)
            
            promise.succeed(Chat(chat))
        }
        
        return promise.futureResult
    }
    
    let readableChat = readableChats.grouped(IMChatMiddleware).grouped(":\(IMChatResourceKey)")
    let writableChat = writableChats.grouped(IMChatMiddleware).grouped(":\(IMChatResourceKey)")
    
    /**
     Gets a specific chat with its ID
     */
    readableChat.get { req -> Chat in
        return req.chat
    }
    
    /**
     Re-joins a chat. This doesn't always work, nor well.
     */
    writableChat.get("join") { req -> Chat in
        req.imChat.join()
        
        return req.chat
    }
    
    /**
     Delete a chat
     */
    writableChat.delete { req -> Chat in
        if req.imChat.isBusinessChat {
            req.imChat.closeSession()
        }
        
        req.imChat.deleteAllHistory()
        
        if req.imChat.isSingle && req.imChat.recipient == nil { req.imChat.remove() }
        else if req.imChat.account.service.isLegacyService { req.imChat.leave() }
        
        return req.chat
    }
    
    /**
     Rename a chat
     */
    writableChat.patch("name") { req -> Chat in
        guard let rename = try? req.content.decode(RenameChat.self) else { throw Abort(.badRequest) }
        
        req.imChat._setDisplayName(rename.name)
        
        return req.chat
    }
    
    writableChat.post("typing") { req -> HTTPStatus in
        req.chat.startTyping()
        
        return .noContent
    }
    
    writableChat.delete("typing") { req -> HTTPStatus in
        req.chat.stopTyping()
        
        return .noContent
    }
    
    writableChat.post("read") { req -> HTTPStatus in
        req.imChat.markAllMessagesAsRead()
        
        if req.imChat.readReceipts {
            IMChatRegistry.shared._chat_sendReadReceipt(forAllMessages: req.imChat)
        }
        
        return .noContent
    }
    
    readableChat.get("properties") { req -> ChatConfigurationRepresentation in
        req.imChat.properties
    }
    
    writableChat.patch("properties") { req -> ChatConfigurationRepresentation in
        guard let patch = try? req.content.decode(ChatPropertiesPatch.self) else { throw Abort(.badRequest) }
        
        req.imChat.readReceipts = patch.readReceipts ?? req.imChat.readReceipts
        req.imChat.ignoreAlerts = patch.ignoreAlerts ?? req.imChat.ignoreAlerts
        
        return req.imChat.properties
    }
    
    bindChatMessagesAPI(readableChat: readableChat, writableChat: writableChat)
    bindParticipantsAPI(readableChat: readableChat, writableChat: writableChat)
}
