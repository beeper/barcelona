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

extension Chat: Content {
    
}

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
private let log_participantAPI = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "ParticipantAPI")
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
    
    let chat = chats.grouped(":groupID")
    
    /**
     Gets a specific chat with its GroupID
     */
    chat.get { req -> EventLoopFuture<Chat> in
        guard let groupID = req.parameters.get("groupID") else { throw Abort(.badRequest) }
        guard let chat = Registry.sharedInstance.imChat(withGroupID: groupID) else {
            os_log("Couldn't find chat with GroupID %@", groupID, log_chatAPI)
            throw Abort(.notFound)
        }
        
        return req.eventLoop.makeSucceededFuture(Chat(chat))
    }
    
    /**
     Re-joins a chat. This doesn't always work, nor well.
     */
    chat.get("join") { req -> EventLoopFuture<Chat> in
        guard let groupID = req.parameters.get("groupID") else { throw Abort(.badRequest) }
        guard let chat = Registry.sharedInstance.imChat(withGroupID: groupID) else {
            os_log("Couldn't find chat with GroupID %@", groupID, log_chatAPI)
            throw Abort(.notFound)
        }
        
        chat.join()
        
        return req.eventLoop.makeSucceededFuture(Chat(chat))
    }
    
    /**
     Delete a chat
     */
    chat.delete { req -> EventLoopFuture<Chat> in
        guard let groupID = req.parameters.get("groupID") else { throw Abort(.badRequest) }
        guard let chat = Registry.sharedInstance.imChat(withGroupID: groupID) else { throw Abort(.notFound) }
        
        let promise = req.eventLoop.makePromise(of: Chat.self)
        
        req.eventLoop.submit {
            if chat.isBusinessChat {
                chat.closeSession()
            }
            
            chat.deleteAllHistory()
            
            if chat.chatStyle == 0x2d && chat.recipient == nil { chat.remove() }
            else if chat.account.service.isLegacyService { chat.leave() }
            
            promise.succeed(Chat(chat))
        }
        
        return promise.futureResult
    }
    
    /**
     Rename a chat
     */
    chat.patch("name") { req -> EventLoopFuture<Chat> in
        guard let rename = try? req.content.decode(RenameChat.self), let groupID = req.parameters.get("groupID") else { throw Abort(.badRequest) }
        guard let chat = Registry.sharedInstance.imChat(withGroupID: groupID) else {
            throw Abort(.notFound)
        }
        
        let promise = req.eventLoop.makePromise(of: Chat.self)
        
        req.eventLoop.submit {
            chat._setDisplayName(rename.name)
            
            promise.succeed(Chat(chat))
        }
        
        return promise.futureResult
    }
    
    chat.post("typing") { req -> EventLoopFuture<HTTPStatus> in
        return req.eventLoop.submit {
            guard let groupID = req.parameters.get("groupID") else { throw Abort(.badRequest) }
            guard let chat = Registry.sharedInstance.imChat(withGroupID: groupID) else {
                throw Abort(.notFound)
            }
            
            chat.localUserIsTyping = true
            
            return .noContent
        }
    }
    
    chat.delete("typing") { req -> EventLoopFuture<HTTPStatus> in
        return req.eventLoop.submit {
            guard let groupID = req.parameters.get("groupID") else { throw Abort(.badRequest) }
            guard let chat = Registry.sharedInstance.imChat(withGroupID: groupID) else {
                throw Abort(.notFound)
            }
            
            chat.localUserIsTyping = false
            
            return .noContent
        }
    }
    
    chat.post("read") { req -> EventLoopFuture<HTTPStatus> in
        return req.eventLoop.submit {
            guard let groupID = req.parameters.get("groupID") else { throw Abort(.badRequest) }
            guard let chat = Registry.sharedInstance.imChat(withGroupID: groupID) else {
                throw Abort(.notFound)
            }
            
            let readReceipts = chat.value(forChatProperty: "EnableReadReceiptForChat") as? Bool ?? false
            
            chat.markAllMessagesAsRead()
            
            if readReceipts {
                IMChatRegistry.shared._chat_sendReadReceipt(forAllMessages: chat)
            }
            
            return .noContent
        }
    }
    
    chat.get("properties") { req -> EventLoopFuture<ChatConfigurationRepresentation> in
        return req.eventLoop.submit {
            guard let groupID = req.parameters.get("groupID") else { throw Abort(.badRequest) }
            guard let chat = Registry.sharedInstance.imChat(withGroupID: groupID) else {
                throw Abort(.notFound)
            }
            
            return chat.properties;
        }
    }
    
    chat.patch("properties") { req -> EventLoopFuture<ChatConfigurationRepresentation> in
        return req.eventLoop.submit {
            guard let groupID = req.parameters.get("groupID"), let patch = try? req.content.decode(ChatPropertiesPatch.self) else { throw Abort(.badRequest) }
            guard let chat = Registry.sharedInstance.imChat(withGroupID: groupID) else {
                throw Abort(.notFound)
            }
            
            chat.readReceipts = patch.readReceipts ?? chat.readReceipts
            chat.ignoreAlerts = patch.ignoreAlerts ?? chat.ignoreAlerts
            
            return chat.properties
        }
    }
    
    bindChatMessagesAPI(chat)
    bindParticipantsAPI(chat)
}

// MARK: - Participants
private func bindParticipantsAPI(_ chat: RoutesBuilder) {
    let participants = chat.grouped("participants")
    
    /**
     Lookup participants of a chat
     */
    participants.get { req -> EventLoopFuture<BulkHandleIDRepresentation> in
        guard let groupID = req.parameters.get("groupID") else { throw Abort(.badRequest) }
        guard let chat = Registry.sharedInstance.chat(withGroupID: groupID) else {
            os_log("Couldn't find chat with GroupID %@", groupID, log_chatAPI)
            throw Abort(.notFound)
        }
        
        return req.eventLoop.makeSucceededFuture(chat.participantIDs)
    }
    
    // MARK: - Participant Management
    
    /**
     Manage the state of a set of participants
     */
    func toggleParticipants(_ add: Bool, req: Request) throws -> EventLoopFuture<BulkHandleIDRepresentation> {
        guard let groupID = req.parameters.get("groupID") else { throw Abort(.badRequest) }
        guard let chat = Registry.sharedInstance.imChat(withGroupID: groupID) else {
            os_log("Couldn't find chat with GroupID %@", groupID, log_chatAPI)
            throw Abort(.notFound)
        }
        
        /*
         {"handles":["1234","eric@net.com"]}
         */
        guard let insertion = try? req.content.decode(BulkHandleIDRepresentation.self) else {
            os_log("Got a malformed payload from client, bailing", log_chatAPI)
            throw Abort(.badRequest)
        }
        
        let promise = req.eventLoop.makePromise(of: BulkHandleIDRepresentation.self)
        
        req.eventLoop.submit {
            let handles = insertion.handles.compactMap { Registry.sharedInstance.imHandle(withID: $0) }
            
            if add {
                if !chat.canAddParticipants(handles) {
                    os_log("Can't add participants to this chat, bailing", log_chatAPI)
                    promise.fail(Abort(.badRequest, reason: "You can't add pariticpants to this group."))
                    return
                }
                
                let reasonMessage = IMMessage.instantMessage(withText: NSAttributedString(string: "Get in my fucking van, kid."), messageSubject: nil, flags: 0x5)
                
                chat.inviteParticipantsToiMessageChat(handles, reason: reasonMessage)
            } else {
                let reasonMessage = IMMessage.instantMessage(withText: NSAttributedString(string: "Goodbye, skank."), messageSubject: nil, flags: 0x5)
                
                chat.removeParticipantsFromiMessageChat(handles, reason: reasonMessage)
            }
            
            promise.succeed(BulkHandleIDRepresentation(handles: chat.participantHandleIDs()))
        }
        
        return promise.futureResult
    }
    
    /**
     Add participants to a chat
     */
    participants.put { req -> EventLoopFuture<BulkHandleIDRepresentation> in
        return try toggleParticipants(true, req: req)
    }
    
    /**
     Remove participants from a chat
     */
    participants.delete { req -> EventLoopFuture<BulkHandleIDRepresentation> in
        return try toggleParticipants(false, req: req)
    }
}

