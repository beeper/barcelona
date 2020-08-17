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

extension DeleteMessage: Content { }
extension DeleteMessageRequest: Content { }

func bindMessagesAPI(_ app: Application) {
    let messages = app.grouped("messages")
    
    let associated = messages.grouped("associated")
    
    let chatItemGUIDExtractor = try! NSRegularExpression(pattern: "(?:\\w+:(\\d+))\\/([\\w-]+)")
    
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
    
    associated.post { req -> EventLoopFuture<HTTPStatus> in
        guard let itemGUID: String = try? req.query.get(String.self, at: "item"),
            let ackType = try? req.query.get(Int.self, at: "type"),
            let parts = itemGUID.groups(for: chatItemGUIDExtractor).first,
            let part = Int(parts[1]),
            let messageGUID = parts[safe: 2] else {
            throw Abort(.badRequest)
            
        }
        
        return Chat.chat(forMessage: messageGUID, on: req.eventLoop).flatMap { chat in
            guard let chat = chat?.imChat() else {
                return req.eventLoop.makeFailedFuture(Abort(.notFound, reason: "Unknown chat."))
            }

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
    
    bindTapbacksAPI(message)
    
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

// MARK: - Tapbacks
private func bindTapbacksAPI(_ message: RoutesBuilder) {
    let tapbacks = message.grouped("tapbacks")
    
    /**
     Send a tapback
     */
    tapbacks.post { req -> EventLoopFuture<HTTPStatus> in
        guard let messageGUID = req.parameters.get("messageGUID"), let part = try? req.query.get(Int.self, at: "part"), let ackType = try? req.query.get(Int.self, at: "type") else { throw Abort(.badRequest) }
        
        return Chat.chat(forMessage: messageGUID, on: req.eventLoop).flatMap { chat in
            guard let chat = chat?.imChat() else {
                return req.eventLoop.makeFailedFuture(Abort(.notFound, reason: "Unknown chat."))
            }
            
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
}
