//
//  Tapbacks.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/7/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import Vapor
import IMCore

struct BulkTapbackRepresentation: Content {
    var representations: [TapbackRepresentation]
}

struct TapbackRepresentation: Content {
    var handle: String
    var chatGroupID: String
    var associatedMessageGUID: String
    var associatedMessageType: Int64
}

struct TapbackResult {
    var associatedMessageGUID: String
    var associatedMessageType: Int
    var handle: IMHandle
    var fromMe: Bool
}

extension DBReader {
    func associatedMessages(with guid: String) -> EventLoopFuture<[Message]> {
        let promise = eventLoop.makePromise(of: [Message].self)
        
        do {
            try pool.read { db in
                let messages = try RawMessage
                    .select(RawMessage.Columns.guid, RawMessage.Columns.ROWID)
                    .filter(sql: "associated_message_guid = ?", arguments: [guid])
                    .fetchAll(db)
                
                do {
                    let chatGroupIDs = try messages.map {
                        try self.chatGroupID(forMessageROWID: $0.ROWID, in: db)
                    }
                
                    IMMessage.messages(withGUIDs: messages.map { $0.guid! }, on: eventLoop).map { messages -> [Message] in
                        messages.compactMap { message -> Message? in
                            guard let chatGroupID = chatGroupIDs[messages.index(of: message)!] else {
                                return nil
                            }
                            
                            return Message(message, chatGroupID: chatGroupID)
                        }
                    }.cascade(to: promise)
                } catch {
                    print("Failed to resolve chat group IDs for messages with error \(error)")
                    promise.succeed([])
                    return
                }
            }
        } catch {
           promise.fail(error)
        }
        
        return promise.futureResult
    }
}
