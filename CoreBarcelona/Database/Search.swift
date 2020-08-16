//
//  Search.swift
//  imessage-rest
//
//  Created by Eric Rabil on 8/12/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import Vapor
import GRDB

struct SearchResultRepresentation: Content {
    var guid: String
    var chatGroupID: String
    var text: String
    var sender: String
    var isFromMe: Bool
    var time: Double
    var acknowledgmentType: Int64?
}

struct BulkSearchResultRepresentation: Content {
    var results: [SearchResultRepresentation]
}

extension DBReader {
    func messages(matching text: String, limit: Int) -> EventLoopFuture<BulkSearchResultRepresentation> {
        let promise = eventLoop.makePromise(of: BulkSearchResultRepresentation.self)
        
        do {
            try pool.read { db in
                // MARK: - Message table search
                let results = try RawMessage
                    .order(RawMessage.Columns.date.desc)
                    .filter(RawMessage.Columns.text.uppercased.like("%\(text)%"))
                    .limit(limit)
                    .fetchAll(db)
                
                // MARK: - Result transformation
                let representations: [SearchResultRepresentation] = try results.compactMap { result in
                    // MARK: - Chat resolution
                    guard let chatGroupID = try self.chatGroupID(forMessageROWID: result.ROWID, in: db), let sender = try self.resolveSenderID(forMessage: result, in: db), let guid = result.guid, let text = result.text, let isFromMe = result.is_from_me, let dateNS = result.date else {
                        return nil
                    }
                    
                    let date = NSDate.__im_dateWithNanosecondTimeInterval(sinceReferenceDate: dateNS)
                    
                    // MARK: - Transformation resolution
                    return SearchResultRepresentation(guid: guid, chatGroupID: chatGroupID, text: text, sender: sender, isFromMe: isFromMe == 1, time: (date?.timeIntervalSince1970 ?? 0) * 1000, acknowledgmentType: result.associated_message_type)
                }
                
                promise.succeed(BulkSearchResultRepresentation(results: representations))
            }
        } catch {
            promise.fail(error)
        }
        
        return promise.futureResult
    }
}
