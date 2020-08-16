//
//  Chat+MessagesAPI.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/6/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import GRDB
import Foundation
import IMCore
import DataDetectorsCore
import Vapor
import CoreFoundation

extension Sequence where Element: NSAttributedString {
    func join(withSeparator separator: NSAttributedString) -> NSAttributedString {
        let finalString = NSMutableAttributedString()
        for (index, string) in enumerated() {
            if index > 0 {
                finalString.append(separator)
            }
            finalString.append(string)
        }
        return finalString
    }
}

enum MessagePartType: String, Codable {
    case text = "text"
    case attachment = "attachment"
}

struct MessagePart: Content {
    var type: MessagePartType
    var details: String
}

//struct CreateMessage: Content {
//    var subject: String?
//    var parts: [MessagePart]
//    var isAudioMessage: Bool?
//    var flags: CLongLong?
//    var ballonBundleID: String?
//    var payloadData: String?
//    var expressiveSendStyleID: String?
//}

extension CreateMessage: Content {
    
}

struct CreateChat: Content {
    var participants: [String]
}

struct RenameChat: Content {
    var name: String?
}

struct OKResult: Content {
    var ok: Bool
}

extension DeleteMessage: Content { }
extension DeleteMessageRequest: Content { }

extension MessagesError {
    var abort: Abort {
        Abort(.init(statusCode: code, reasonPhrase: message))
    }
}

func 

func bindMessagesAPI(_ chat: RoutesBuilder) {
    // MARK: - Chat Items
    
    let items = chat.grouped("items")
    
    items.get("associated") { req -> EventLoopFuture<BulkMessageRepresentation> in
        guard let itemGUID = try? req.query.get(String.self, at: "item") else {
            throw Abort(.badRequest)
        }
        
        return DBReader(pool: db, eventLoop: req.eventLoop).associatedMessages(with: itemGUID).map {
            BulkMessageRepresentation($0)
        }
    }
    
    let messages = chat.grouped("messages")
    
    // MARK: - Bulk
    
    /**
     Query messages in a chat
     */
    messages.get { req -> EventLoopFuture<BulkChatItemRepresentation> in
        guard let groupID = req.parameters.get("groupID") else { throw Abort(.badRequest) }
        guard let chat = Registry.sharedInstance.imChat(withGroupID: groupID) else { throw Abort(.notFound) }
        let messageGUID = try? req.query.get(String.self, at: "before")
        var limit = (try? req.query.get(UInt64.self, at: "limit")) ?? 75
        
        if limit > 100 {
            limit = 100
        }
        
        let promise = req.eventLoop.makePromise(of: BulkChatItemRepresentation.self)
        
        chat.loadMessages(before: messageGUID, limit: limit) { messages in
            promise.succeed(BulkChatItemRepresentation(items: messages))
        }
        
        return promise.futureResult
    }
    
    /**
     Create a ChatItem
     */
    messages.grouped(ThrottlingMiddleware(allotment: 30, expiration: 5)).post { req -> EventLoopFuture<BulkMessageRepresentation> in
        guard let creation = try? req.content.decode(CreateMessage.self), let groupID = req.parameters.get("groupID") else { throw Abort(.badRequest) }
        guard let chat = Registry.sharedInstance.chat(withGroupID: groupID) else { throw Abort(.notFound) }
        
        let promise = req.eventLoop.makePromise(of: BulkMessageRepresentation.self)
        
        chat.send(message: creation, on: req.eventLoop).whenComplete { result in
            switch (result) {
            case .success(let messages):
                promise.succeed(messages)
                break
            case .failure(let error):
                if let error = error as? MessagesError {
                    promise.fail(error.abort)
                    return
                }
                
                promise.fail(error)
            }
        }
        
        return promise.futureResult
    }
    
    /**
     Delete a message or subpart from the message
     */
    messages.delete { req -> EventLoopFuture<OKResult> in
        guard let deletion = try? req.content.decode(DeleteMessageRequest.self), let chatGroupID = req.parameters.get("groupID") else { throw Abort(.badRequest) }
        guard let chat = Registry.sharedInstance.chat(withGroupID: chatGroupID) else { throw Abort(.notFound) }
        
        let promise = req.eventLoop.makePromise(of: OKResult.self)
        
        chat.delete(messages: deletion, on: req.eventLoop).whenComplete { result in
            switch result {
            case .failure(let error):
                promise.fail(error)
                break
            case .success(let _):
                promise.succeed(OKResult(ok: true))
            }
        }
        
        return promise.futureResult
    }
    
    // MARK: - Specific
    
    let message = messages.grouped(":messageGUID")
    
    bindTapbacksAPI(message)
    
    /**
     Query a specific message
     */
    message.get { req -> EventLoopFuture<Message> in
        guard let chatGroupID = req.parameters.get("groupID"), let messageGUID = req.parameters.get("messageGUID") else { throw Abort(.badRequest) }
        guard let chat = Registry.sharedInstance.imChat(withGroupID: chatGroupID) else { throw Abort(.notFound) }
        
        let promise = req.eventLoop.makePromise(of: Message.self)
        
        Message.message(withGUID: messageGUID, inChat: chatGroupID, on: req.eventLoop).whenComplete {
            switch $0 {
            case .success(let representation):
                guard let representation = representation else {
                    promise.fail(Abort(.notFound))
                    return
                }
                
                promise.succeed(representation)
            case .failure(let error):
                promise.fail(error)
            }
        }
        
        return promise.futureResult
    }
}

// MARK: - Tapbacks
private func bindTapbacksAPI(_ message: RoutesBuilder) {
    let tapbacks = message.grouped("tapbacks")
    
    /**
     Send a tapback
     */
    tapbacks.post { req -> EventLoopFuture<HTTPStatus> in
        guard let chatGroupID = req.parameters.get("groupID"), let messageGUID = req.parameters.get("messageGUID"), let part = try? req.query.get(Int.self, at: "part"), let ackType = try? req.query.get(Int.self, at: "type") else { throw Abort(.badRequest) }
        guard let chat = Registry.sharedInstance.imChat(withGroupID: chatGroupID) else { throw Abort(.notFound) }
        
        let debugItemType = try? req.query.get(UInt8.self, at: "itemType")
        let promise = req.eventLoop.makePromise(of: HTTPStatus.self)
        
        chat.tapback(guid: messageGUID, index: part, type: ackType, overridingItemType: debugItemType) { error in
            guard let error = error else {
                return promise.succeed(.ok)
            }
            
            promise.fail(error)
        }
        
        return promise.futureResult
    }
}
