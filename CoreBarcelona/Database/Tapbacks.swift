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
    var chatGUID: String
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
    /**
     Load all tapbacks for a given chat item GUID. This must include the part, i.e. p:0/ADOIJGFA-3489GJA-ADFG843-ADNFBAO
     */
    func tapbacks(for chatItem: String) -> EventLoopFuture<BulkTapbackRepresentation> {
        let promise = eventLoop.makePromise(of: BulkTapbackRepresentation.self)
        
        do {
            try pool.read { db in
                // MARK: - Raw query
                let results = try RawMessage.fetchAll(db, sql: "SELECT * FROM message WHERE associated_message_guid = ?", arguments: [chatItem])
                
                var chatGUID: String? = nil
                
                let representations = try results.compactMap { message -> TapbackRepresentation? in
                    guard let handleRowID = message.handle_id, let associatedMessageGUID = message.associated_message_guid, let associatedMessageType = message.associated_message_type, let fromMeRaw = message.is_from_me else { return nil }
                    
                    // MARK: - Chat resolution
                    if chatGUID == nil {
                        chatGUID = try self.chatGUID(forMessageROWID: message.ROWID, in: db)
                        if chatGUID == nil {
                            return nil
                        }
                    }
                    
                    guard let handleID = try self.resolveSenderID(forMessage: message, in: db) else { return nil }
                    
                    return TapbackRepresentation(handle: handleID, chatGUID: chatGUID!, associatedMessageGUID: associatedMessageGUID, associatedMessageType: associatedMessageType)
                }
                
                // MARK: - Query resolution
                
                promise.succeed(BulkTapbackRepresentation(representations: representations))
            }
        } catch {
            promise.fail(error)
        }
        
        return promise.futureResult
    }
}
