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

extension BarcelonaError {
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
        let messageGUID = try? req.query.get(String.self, at: "before")
        var limit = (try? req.query.get(UInt64.self, at: "limit")) ?? 75
        
        if limit > 100 {
            limit = 100
        }
        
        return req.chat.messages(before: messageGUID, limit: limit).map {
            BulkChatItemRepresentation(items: $0)
        }
    }
    
    /**
     Create a ChatItem
     */
    messages.grouped(ThrottlingMiddleware(allotment: 30, expiration: 5)).post { req -> EventLoopFuture<BulkMessageRepresentation> in
        guard let creation = try? req.content.decode(CreateMessage.self) else { throw Abort(.badRequest) }
        
        req.chat.stopTyping()
        
        return req.chat.send(message: creation, on: req.eventLoop)
    }
}
