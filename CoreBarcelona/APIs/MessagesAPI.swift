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
        
        return Chat.chat(forMessage: messageGUID, on: req.eventLoop).flatMap { chat in
            guard let chat = chat?.imChat() else {
                return req.eventLoop.makeFailedFuture(Abort(.notFound, reason: "Unknown chat."))
            }

            let debugItemType = try? req.query.get(UInt8.self, at: "itemType")
            let promise = req.eventLoop.makePromise(of: Message.self)

            chat.tapback(guid: messageGUID, itemGUID: itemGUID, type: ackType, overridingItemType: debugItemType).whenComplete {
                switch $0 {
                case .success(let message):
                    ERIndeterminateIngestor.ingest(messageLike: message, in: chat.groupID).whenSuccess { message in
                        guard let message = message else {
                            promise.fail(Abort(.internalServerError, reason: "Failde to create tapback message"))
                            return
                        }
                        promise.succeed(message)
                    }
                case .failure(let error):
                    promise.fail(error)
                }
            }

            return promise.futureResult
        }
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
        
        let promise = req.eventLoop.makePromise(of: Message.self)
        
        Message.message(withGUID: messageGUID, on: req.eventLoop).whenComplete {
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
