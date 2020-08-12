//
//  Tapbacks.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/7/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import Vapor
import GRDB

struct BulkTapbackRepresentation: Content {
    var representations: [TapbackRepresentation]
}

struct TapbackRepresentation: Content {
    var handle: String
    var chatGUID: String
    var associatedMessageGUID: String
    var associatedMessageType: Int64
}

struct SearchResultRepresentation: Content {
    var guid: String
    var chatGUID: String
    var text: String
    var sender: String
    var isFromMe: Bool
    var time: Double
    var acknowledgmentType: Int64?
}

struct BulkSearchResultRepresentation: Content {
    var results: [SearchResultRepresentation]
}

let db = try! DatabasePool(path: "/Users/ericrabil/Library/Messages/chat.db")

struct DBReader {
    var pool: DatabasePool
    var eventLoop: EventLoop
    
    func messages(matching text: String, limit: Int) -> EventLoopFuture<BulkSearchResultRepresentation> {
        let promise = eventLoop.makePromise(of: BulkSearchResultRepresentation.self)
        
        do {
            try pool.read { db in
                let results = try RawMessage
                    .order(RawMessage.Columns.date.desc)
                    .filter(RawMessage.Columns.text.uppercased.like("%\(text)%"))
                    .limit(limit)
                    .fetchAll(db)
                
                let representations: [SearchResultRepresentation] = try results.compactMap { result in
                    guard let chatGUID = try self.chatGUID(forMessageROWID: result.ROWID, in: db), let sender = try self.resolveSenderID(forMessage: result, in: db), let guid = result.guid, let text = result.text, let isFromMe = result.is_from_me, let dateNS = result.date else {
                        return nil
                    }
                    
                    let date = NSDate.__im_dateWithNanosecondTimeInterval(sinceReferenceDate: dateNS)
                    
                    return SearchResultRepresentation(guid: guid, chatGUID: chatGUID, text: text, sender: sender, isFromMe: isFromMe == 1, time: (date?.timeIntervalSince1970 ?? 0) * 1000, acknowledgmentType: result.associated_message_type)
                }
                
                promise.succeed(BulkSearchResultRepresentation(results: representations))
            }
        } catch {
            promise.fail(error)
        }
        
        return promise.futureResult
    }
    
    func chatGUID(forMessageROWID ROWID: Int64, in db: Database) throws -> String? {
        guard let joinResult = try ChatMessageJoin
            .select(ChatMessageJoin.Columns.chat_id, as: Int64.self)
            .filter(ChatMessageJoin.Columns.message_id == ROWID)
            .fetchOne(db) else {
            return nil
        }
        
        guard let guid = try RawChat
            .select(RawChat.Columns.guid, as: String.self)
            .filter(RawChat.Columns.ROWID == joinResult)
            .fetchOne(db) else {
                return nil
        }
        
        return guid
    }
    
    func resolveSenderID(forMessage message: RawMessage, in db: Database) throws -> String? {
        if message.is_from_me == 1 {
            return Registry.sharedInstance.iMessageAccount()!.arrayOfAllIMHandles[0].id
        } else {
            guard let handleRowID = message.handle_id, let rawHandle = try RawHandle.fetchOne(db, sql: "SELECT * FROM handle WHERE ROWID = ?", arguments: [handleRowID]) else { return nil }
            
            return rawHandle.id
        }
    }
    
    func tapbacks(for chatItem: String) -> EventLoopFuture<BulkTapbackRepresentation> {
        let promise = eventLoop.makePromise(of: BulkTapbackRepresentation.self)
        
        do {
            try pool.read { db in
                let results = try RawMessage.fetchAll(db, sql: "SELECT * FROM message WHERE associated_message_guid = ?", arguments: [chatItem])
                
                var chatGUID: String? = nil
                
                let representations = try results.compactMap { message -> TapbackRepresentation? in
                    guard let handleRowID = message.handle_id, let associatedMessageGUID = message.associated_message_guid, let associatedMessageType = message.associated_message_type, let fromMeRaw = message.is_from_me else { return nil }
                    
                    if chatGUID == nil {
                        chatGUID = try self.chatGUID(forMessageROWID: message.ROWID, in: db)
                        if chatGUID == nil {
                            return nil
                        }
                    }
                    
                    guard let handleID = try self.resolveSenderID(forMessage: message, in: db) else { return nil }
                    
                    return TapbackRepresentation(handle: handleID, chatGUID: chatGUID!, associatedMessageGUID: associatedMessageGUID, associatedMessageType: associatedMessageType)
                }
                
                promise.succeed(BulkTapbackRepresentation(representations: representations))
            }
        } catch {
            promise.fail(error)
        }
        
        return promise.futureResult
    }
}

//import SQLite

//private let handles = Table("handle")
//private let handleRowID = Expression<Int>("ROWID")
//private let handleID = Expression<String>("id")
//
//struct HandlesReader {
//    var db: Connection
//
//    func readHandle(forRowID rowID: Int) -> Handle? {
//        if let handle = try? db.pluck(handles.filter(handleRowID == rowID)) {
//            let id = handle[handleID]
//
//            if let handleObject = Registry.sharedInstance.handle(withID: id) {
//                return handleObject
//            }
//        }
//
//        return nil
//    }
//}
//
struct TapbackResult {
    var associatedMessageGUID: String
    var associatedMessageType: Int
    var handle: IMHandle
    var fromMe: Bool
}
//
//struct TapbacksReader {
//    var db: Connection
//
//    func readTapbacks(for messageGUID: String) {
//        let messages = Table("message")
//        let associated_message_guid = Expression<String?>("associated_message_guid")
//        let handle = Expression<Int?>("handle_id")
//        let associated_type = Expression<Int?>("associated_message_type")
//        let from_me = Expression<Int?>("is_from_me")
//
//        if let results = try? db.prepare(messages.filter(associated_message_guid == messageGUID)) as? AnySequence<SQLite.Row> {
//            results.forEach { result in
//                guard let tapbackGUID = result[associated_message_guid], let tapbackHandle = result[handle], let associatedType = result[associated_type], let fromMe = result[from_me] else {
//                    return
//                }
//
//                tapb
//            }
//        }
//    }
//}
