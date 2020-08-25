//
//  ChatMessageJoin.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/8/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import GRDB
import NIO

/**
 Represents the chat-message join table in the chat.db file
 */
class ChatMessageJoin: Record {
    override class var databaseTableName: String { "chat_message_join" }
    
    required init(row: Row) {
        chat_id = row[Columns.chat_id]
        message_id = row[Columns.message_id]
        message_date = row[Columns.message_date]
        super.init(row: row)
    }
    
    override func encode(to container: inout PersistenceContainer) {
        container[Columns.chat_id] = chat_id
        container[Columns.message_id] = message_id
        container[Columns.message_date] = message_date
    }
    
    enum Columns: String, ColumnExpression {
        case chat_id, message_id, message_date
    }
    
    var chat_id: Int64?
    var message_id: Int64?
    var message_date: Int64?
}

extension DBReader {
    func chatGroupID(forMessageGUID guid: String) -> EventLoopFuture<String?> {
        let promise = eventLoop.makePromise(of: String?.self)
        
        pool.asyncRead {
            switch $0 {
            case .failure(let error):
                promise.fail(error)
            case .success(let db):
                do {
                    guard let ROWID = try RawMessage
                        .select(RawMessage.Columns.ROWID, as: Int64.self)
                        .filter(RawMessage.Columns.guid == guid)
                        .fetchOne(db) else {
                            promise.succeed(nil)
                            return
                    }
                    
                    self.chatGroupID(forMessageROWID: ROWID).cascade(to: promise)
                } catch {
                    promise.fail(error)
                }
            }
        }
        
        return promise.futureResult
    }
    
    /**
     Resolve the chat GroupID for a given message ROWID
     */
    func chatGroupID(forMessageROWID ROWID: Int64) -> EventLoopFuture<String?> {
        return self.chatGroupIDs(forMessageRowIDs: [ROWID]).map {
            $0[ROWID]
        }
    }
    
    func chatGroupIDs(forMessageRowIDs ROWIDs: [Int64]) -> EventLoopFuture<[Int64: String]> {
        let promise = eventLoop.makePromise(of: [Int64: String].self)
        
        pool.asyncRead {
            switch $0 {
            case .failure(let error):
                promise.fail(error)
            case .success(let db):
                do {
                    let joins = try ChatMessageJoin
                        .filter(ROWIDs.contains(ChatMessageJoin.Columns.message_id))
                        .fetchAll(db)
                    
                    let chatRowIDs = joins.compactMap {
                        $0.chat_id
                    }
                    
                    let chatPartials = try RawChat
                        .select([RawChat.Columns.group_id, RawChat.Columns.ROWID])
                        .filter(chatRowIDs.contains(RawChat.Columns.ROWID))
                        .fetchAll(db)
                    
                    let chatRowIDToGroupID = chatPartials.reduce(into: [Int64: String]()) { (ledger, partial) in
                        guard let ROWID = partial.ROWID, let groupID = partial.group_id else {
                            return
                        }
                        
                        ledger[ROWID] = groupID
                    }
                    
                    promise.succeed(joins.reduce(into: [Int64: String]()) { (ledger, join) in
                        guard let chatROWID = join.chat_id, let messageROWID = join.message_id, let chatGroupID = chatRowIDToGroupID[chatROWID] else {
                            return
                        }
                        
                        ledger[messageROWID] = chatGroupID
                    })
                } catch {
                    promise.fail(error)
                }
            }
        }
        
        return promise.futureResult
    }
    
    func newestMessageGUIDs(inChatROWID ROWID: Int64, beforeMessageGUID: String? = nil, limit: Int = 100) -> EventLoopFuture<[String]> {
        let promise = eventLoop.makePromise(of: [String].self)
        
        let resolution = beforeMessageGUID == nil ? eventLoop.makeSucceededFuture(nil) : rowID(forMessageGUID: beforeMessageGUID!)
        
        resolution.whenSuccess { beforeMessageROWID in
            self.pool.asyncRead {
                switch $0 {
                case .failure(let error):
                    promise.fail(error)
                case .success(let db):
                    do {
                        var messageROWIDsQuery = ChatMessageJoin
                            .select(ChatMessageJoin.Columns.message_id, as: Int64.self)
                            .filter(ChatMessageJoin.Columns.chat_id == ROWID)
                        
                        if let beforeMessageROWID = beforeMessageROWID {
                            messageROWIDsQuery = messageROWIDsQuery
                                .filter(ChatMessageJoin.Columns.message_id <= beforeMessageROWID)
                        }
                        
                        let messageROWIDs = try messageROWIDsQuery
                            .order(ChatMessageJoin.Columns.message_id.desc)
                            .limit(limit)
                            .fetchAll(db)
                        
                        let guids = try RawMessage
                            .select(RawMessage.Columns.guid, as: String.self)
                            .filter(messageROWIDs.contains(RawMessage.Columns.ROWID))
                            .order(RawMessage.Columns.ROWID.desc)
                            .fetchAll(db)
                        
                        promise.succeed(guids)
                    } catch {
                        promise.fail(error)
                    }
                }
            }
        }
        
        return promise.futureResult
    }
}
