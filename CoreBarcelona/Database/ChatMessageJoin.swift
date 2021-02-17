//
//  ChatMessageJoin.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/8/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import GRDB
import NIO

/**
 Represents the chat-message join table in the chat.db file
 */
class ChatMessageJoin: Record {
    override class var databaseTableName: String { "chat_message_join" }
    
    static let message = belongsTo(RawMessage.self, using: ForeignKey(["message_id"], to: ["ROWID"]))
    
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
    /// Returns the chat ROWID for a message with the given GUID
    /// - Parameter guid: guid of the message to query
    /// - Returns: ROWID of the chat the message resides in
    func chatRowID(forMessageGUID guid: String) -> EventLoopFuture<Int64?> {
        let promise = eventLoop.makePromise(of: Int64?.self)
        
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
                    
                    promise.succeed(ROWID)
                } catch {
                    promise.fail(error)
                }
            }
        }
        
        return promise.futureResult
    }
    
    /// Returns the chat id for a message with the given GUID
    /// - Parameter guid: guid of the message to query
    /// - Returns: identifier of the chat the message resides in
    func chatIdentifier(forMessageGUID guid: String) -> EventLoopFuture<String?> {
        if ERBarcelonaManager.isSimulation {
            return eventLoop.makeSucceededFuture(IMChatRegistry.shared._chats(withMessageGUID: guid).first?.id)
        }
        
        return chatRowID(forMessageGUID: guid).flatMap { ROWID in
            guard let ROWID = ROWID else {
                return self.eventLoop.makeSucceededFuture(nil)
            }
            
            return self.chatIdentifier(forMessageRowID: ROWID)
        }
    }
    
    /// Returns the chat id for a message with the given ROWID
    /// - Parameter ROWID: ROWID of the message to query
    /// - Returns: identifier of the chat the message resides in
    func chatIdentifier(forMessageRowID ROWID: Int64) -> EventLoopFuture<String?> {
        return self.chatIdentifiers(forMessageRowIDs: [ROWID]).map {
            $0[ROWID]
        }
    }
    
    /// Returns a ledger of partial chats for the given message IDs
    /// - Parameters:
    ///   - ROWIDs: ROWIDs to resolve chats from
    ///   - baseColumns: columns to return in the chat objects
    /// - Returns: ledger of message ROWID to chat partials
    private func partialChats(forMessageRowIDs ROWIDs: [Int64], baseColumns: [RawChat.Columns]) -> EventLoopFuture<[Int64: RawChat]> {
        let promise = eventLoop.makePromise(of: [Int64: RawChat].self)
        
        var columns = baseColumns
        if !columns.contains(where: {
            $0 == RawChat.Columns.ROWID
        }) {
            columns.append(RawChat.Columns.ROWID)
        }
        
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
                        .select(columns)
                        .filter(chatRowIDs.contains(RawChat.Columns.ROWID))
                        .fetchAll(db)
                    
                    let chatLedger = chatPartials.reduce(into: [Int64: RawChat]()) { (ledger, partial) in
                        guard let ROWID = partial.ROWID else {
                            return
                        }
                        
                        ledger[ROWID] = partial
                    }
                    
                    promise.succeed(joins.reduce(into: [Int64: RawChat]()) { (ledger, join) in
                        guard let chatROWID = join.chat_id, let messageROWID = join.message_id, let chat = chatLedger[chatROWID] else {
                            return
                        }
                        
                        ledger[messageROWID] = chat
                    })
                } catch {
                    promise.fail(error)
                }
            }
        }
        
        return promise.futureResult
    }
    
    /// Resolves the identifiers for chats with the given identifiers
    /// - Parameter ROWIDs: message ROWIDs to resolve
    /// - Returns: ledger of message ROWID to chat identifier
    func chatIdentifiers(forMessageRowIDs ROWIDs: [Int64]) -> EventLoopFuture<[Int64: String]> {
        partialChats(forMessageRowIDs: ROWIDs, baseColumns: [RawChat.Columns.chat_identifier]).map {
            $0.compactMapValues {
                $0.chat_identifier
            }
        }
    }
    
    /// Resolves the most recent GUIDs for chats with the given ROWIDs
    /// - Parameters:
    ///   - ROWIDs: ROWIDs of the chats to resolve
    ///   - beforeMessageGUID: message GUID to load messages before
    ///   - limit: max number of results to return
    /// - Returns: array of message GUIDs matching the query
    func newestMessageGUIDs(inChatROWIDs ROWIDs: [Int64], beforeMessageGUID: String? = nil, limit: Int? = nil) -> EventLoopFuture<[String]> {
        let promise = eventLoop.makePromise(of: [String].self)
        
        let resolution = beforeMessageGUID == nil ? eventLoop.makeSucceededFuture(nil) : rowID(forMessageGUID: beforeMessageGUID!)
        
        resolution.whenSuccess { beforeMessageROWID in
            let guidFetchTracker = ERTrack(log: .default, name: "ChatMessageJoin.swift:newestMessageGUIDs Loading newest guids for chat", format: "")
            
            self.pool.asyncRead {
                guidFetchTracker()
                
                switch $0 {
                case .failure(let error):
                    promise.fail(error)
                case .success(let db):
                    let ROWIDQuery = ERTrack(log: .default, name: "ChatMessageJoin.swift:newestMessageGUIDs Loading message ROWIDs", format: "")
                    
                    do {
                        var messageROWIDsQuery = ChatMessageJoin
                            .select(ChatMessageJoin.Columns.message_id, as: Int64.self)
                            .filter(ROWIDs.contains(ChatMessageJoin.Columns.chat_id))
                        
                        if let beforeMessageROWID = beforeMessageROWID {
                            messageROWIDsQuery = messageROWIDsQuery
                                .filter(ChatMessageJoin.Columns.message_id <= beforeMessageROWID)
                        }
                        
                        let messageROWIDs = try messageROWIDsQuery
                            .order(ChatMessageJoin.Columns.message_date.desc)
                            .limit(limit ?? ERDefaultMessageQueryLimit)
                            .fetchAll(db)
                        
                        ROWIDQuery()
                        
                        guard messageROWIDs.count > 0 else {
                            promise.succeed([])
                            return
                        }
                        
                        let rawMessageFetcher = ERTrack(log: .default, name: "ChatMessageJoin.swift:newestMessageGUIDs Fetching RawMessage for message ROWIDs", format: "")
                        
                        let guids = try RawMessage
                            .select(RawMessage.Columns.guid, as: String.self)
                            .filter(messageROWIDs.contains(RawMessage.Columns.ROWID))
                            .order(RawMessage.Columns.ROWID.desc)
                            .fetchAll(db)
                        
                        rawMessageFetcher()
                        
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
