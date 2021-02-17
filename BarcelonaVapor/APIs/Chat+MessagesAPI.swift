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
import CoreBarcelona

extension BarcelonaError {
    var abort: Abort {
        Abort(.init(statusCode: code, reasonPhrase: message))
    }
}

func bindChatMessagesAPI(readableChat: RoutesBuilder, writableChat: RoutesBuilder) {
    let readableMessages = readableChat.grouped("messages")
    let writableMessages = writableChat.grouped("messages")
    
    // MARK: - Bulk
    
    /**
     Query messages in a chat
     */
    readableMessages.get { req -> EventLoopFuture<BulkMessageRepresentation> in
        let messageGUID = try? req.query.get(String.self, at: "before")
        let limit = (try? req.query.get(Int.self, at: "limit")) ?? ERDefaultMessageQueryLimit
        
        
        return req.chat.messages(before: messageGUID, limit: limit).map {
            BulkMessageRepresentation($0.compactMap {
                guard case .message(let message) = $0 else {
                    return nil
                }
                
                return message
            })
        }
    }
        
    let messageSending = writableMessages.grouped(ThrottlingMiddleware(allotment: 30, expiration: 5))
    
    /**
     Create a ChatItem
     */
    messageSending.post { req -> EventLoopFuture<BulkMessageRepresentation> in
        guard let creation = try? req.content.decode(CreateMessage.self) else { throw Abort(.badRequest) }
        
        req.chat.stopTyping()
        
        return req.chat.send(message: creation, on: req.eventLoop)
    }
    
    messageSending.post("plugin") { req -> EventLoopFuture<BulkMessageRepresentation> in
        guard let creation = try? req.content.decode(CreatePluginMessage.self) else { throw Abort(.badRequest) }
        
        req.chat.stopTyping()
        
        return req.chat.send(message: creation, on: req.eventLoop)
    }
}
