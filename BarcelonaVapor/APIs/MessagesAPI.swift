//
//  MessagesAPI.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 8/16/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import CoreBarcelona
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

func bindMessagesAPI(_ app: RoutesBuilder) {
    let messages = app.grouped("messages")
    let readableMessages = messages.grouped(TokenGrant.readMessages)
    let writableMessages = messages.grouped(TokenGrant.writeMessages)
    
    readableMessages.get { req -> EventLoopFuture<BulkMessageRepresentation> in
        guard var ids = try? req.query.get([String].self, at: "ids") else {
            throw Abort(.badRequest)
        }
        
        ids = ids.map {
            $0.replacingOccurrences(of: "\n", with: "")
        }
        
        return Message.lazyResolve(withIdentifiers: ids).map {
            $0.representation
        }
    }
    
    let associated = messages.grouped("associated")
    let readableAssociated = associated.grouped(TokenGrant.readMessages)
    let writableAssociated = associated.grouped(TokenGrant.writeMessages)
    
    /**
     Pull associated messages for a given chat item
     */
    readableAssociated.get { req -> EventLoopFuture<BulkMessageRepresentation> in
        guard let itemGUID = try? req.query.get(String.self, at: "item") else {
            throw Abort(.badRequest)
        }
        
        return Message.associatedMessages(withGUID: itemGUID).map {
            $0.representation
        }
    }
    
    writableAssociated.post { req -> EventLoopFuture<Message> in
        guard let creation = try? req.content.decode(TapbackCreation.self) else {
            throw Abort(.badRequest, reason: "Malformed body")
        }
        
        let itemGUID = creation.item
        let messageGUID = creation.message
        let ackType = creation.type
        
        let promise = req.eventLoop.makePromise(of: Message.self)
        
        IMChat.chat(forMessage: messageGUID).flatMap { chat -> EventLoopFuture<Message?> in
            guard let chat = chat else {
                return req.eventLoop.makeFailedFuture(Abort(.notFound, reason: "Unknown chat."))
            }

            let debugItemType = try? req.query.get(UInt8.self, at: "itemType")

            return chat.tapback(guid: messageGUID, itemGUID: itemGUID, type: ackType, overridingItemType: debugItemType).flatMap {
                ERIndeterminateIngestor.ingest(messageLike: $0, in: chat.id)
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
    writableMessages.delete { req -> EventLoopFuture<OKResult> in
        guard let deletion = try? req.content.decode(DeleteMessageRequest.self) else { throw Abort(.badRequest) }
        if deletion.messages.count == 0 {
            return req.eventLoop.makeSucceededFuture(OKResult(ok: true))
        }
        
        let promise = req.eventLoop.makePromise(of: OKResult.self)
        
        EventLoopFuture<OKResult>.whenAllComplete(deletion.messages.map { message -> EventLoopFuture<OKResult> in
            message.chat().flatMap { chat -> EventLoopFuture<OKResult> in
                guard let chat = chat else {
                    return req.eventLoop.makeFailedFuture(Abort(.notFound, reason: "Unknown chat."))
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
    
    let message = messages.grouped(MessageMiddleware).grouped(":\(IMMessageResourceKey)")
    let readableMessage = message.grouped(TokenGrant.readMessages)
    
    /**
     Query a specific message
     */
    readableMessage.get { req -> Message in
        req.message
    }
}
