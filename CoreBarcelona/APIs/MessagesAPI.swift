//
//  MessagesAPI.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 8/16/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import Vapor
import IMCore

struct OKResult: Content {
    var ok: Bool
}

struct TapbackCreation: Content {
    var item: String
    var message: String
    var type: Int
}

extension DeleteMessage: Content { }
extension DeleteMessageRequest: Content { }

func bindMessagesAPI(_ app: Application) {
    let messages = app.grouped("messages")
    
    messages.get { req -> EventLoopFuture<BulkMessageRepresentation> in
        guard var guids = try? req.query.get([String].self, at: "guids") else {
            throw Abort(.badRequest)
        }
        
        guids = guids.map {
            $0.replacingOccurrences(of: "\n", with: "")
        }
        
        return Message.messages(withGUIDs: guids, on: messageQuerySystem.next()).map {
            $0.representation
        }
    }
    
    let associated = messages.grouped("associated")
    
    /**
     Pull associated messages for a given chat item
     */
    associated.get { req -> EventLoopFuture<BulkMessageRepresentation> in
        guard let itemGUID = try? req.query.get(String.self, at: "item") else {
            throw Abort(.badRequest)
        }
        
        return DBReader(pool: databasePool, eventLoop: req.eventLoop).associatedMessages(with: itemGUID).map {
            BulkMessageRepresentation($0)
        }
    }
    
    associated.post { req -> EventLoopFuture<Message> in
        guard let creation = try? req.content.decode(TapbackCreation.self) else {
            throw Abort(.badRequest, reason: "Malformed body")
        }
        
        let itemGUID = creation.item
        let messageGUID = creation.message
        let ackType = creation.type
        
        let promise = req.eventLoop.makePromise(of: Message.self)
        
        Chat.chat(forMessage: messageGUID, on: req.eventLoop).flatMap { chat -> EventLoopFuture<Message?> in
            guard let chat = chat?.imChat() else {
                return req.eventLoop.makeFailedFuture(Abort(.notFound, reason: "Unknown chat."))
            }

            let debugItemType = try? req.query.get(UInt8.self, at: "itemType")

            return chat.tapback(guid: messageGUID, itemGUID: itemGUID, type: ackType, overridingItemType: debugItemType).flatMap {
                ERIndeterminateIngestor.ingest(messageLike: $0, in: chat.groupID)
            }
        }.flatMapThrowing { message -> Message in
            guard let message = message else {
                throw Abort(.internalServerError, reason: "Failed to send tapback")
            }
            
            return message
        }.cascade(to: promise)
        
        return promise.futureResult
    }
    
    /**
     Delete a message or subpart from the message
     */
    messages.delete { req -> EventLoopFuture<OKResult> in
        guard let deletion = try? req.content.decode(DeleteMessageRequest.self) else { throw Abort(.badRequest) }
        if deletion.messages.count == 0 {
            return req.eventLoop.makeSucceededFuture(OKResult(ok: true))
        }
        
        let promise = req.eventLoop.makePromise(of: OKResult.self)
        
        EventLoopFuture<OKResult>.whenAllComplete(deletion.messages.map { message -> EventLoopFuture<OKResult> in
            let loop = messageQuerySystem.next()
            
            return message.resolveChat(on: loop).flatMap { chat -> EventLoopFuture<OKResult> in
                guard let chat = chat else {
                    return loop.makeFailedFuture(Abort(.notFound, reason: "Unknown chat."))
                }
                
                return chat.delete(message: message, on: req.eventLoop).map { _ in
                    OKResult(ok: true)
                }
            }
        }, on: req.eventLoop).whenComplete { results in
            switch results {
            case .success:
                promise.succeed(OKResult(ok: true))
            case .failure(let error):
                promise.fail(error)
            }
        }
        
        return promise.futureResult
    }
    
    // MARK: - Specific
    
    let message = messages.grouped(":messageGUID")
    
    /**
     Query a specific message
     */
    message.get { req -> EventLoopFuture<Message> in
        guard let messageGUID = req.parameters.get("messageGUID") else { throw Abort(.badRequest) }
        
        return Message.message(withGUID: messageGUID, on: req.eventLoop).flatMapThrowing {
            guard let message = $0 else {
                throw Abort(.notFound, reason: "Unknown message")
            }
            
            return message
        }
    }
}
