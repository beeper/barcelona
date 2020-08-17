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

extension CreateMessage: Content {
    
}

extension MessagesError {
    var abort: Abort {
        Abort(.init(statusCode: code, reasonPhrase: message))
    }
}

func bindChatMessagesAPI(_ chat: RoutesBuilder) {
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
}
