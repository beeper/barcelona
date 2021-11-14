//
//  Chats.swift
//  Barcelona
//
//  Created by Eric Rabil on 7/30/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import BarcelonaFoundation
import GRDB

fileprivate extension DBReader {/// Returns a ledger of partial chats for the given message IDs
    /// - Parameters:
    ///   - ROWIDs: ROWIDs to resolve chats from
    ///   - baseColumns: columns to return in the chat objects
    /// - Returns: ledger of message ROWID to chat partials
    func partialChats(forMessageRowIDs ROWIDs: [Int64], baseColumns: [RawChat.Columns]) -> Promise<[Int64: RawChat]> {
        var columns = baseColumns
        if !columns.contains(where: {
            $0 == RawChat.Columns.ROWID
        }) {
            columns.append(RawChat.Columns.ROWID)
        }
        
        return read { db in
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
            
            let chatLedger = chatPartials.dictionary(keyedBy: \.ROWID)
            
            return joins.reduce(into: [Int64: RawChat]()) { (ledger, join) in
                guard let chatROWID = join.chat_id, let messageROWID = join.message_id, let chat = chatLedger[chatROWID] else {
                    return
                }
                
                ledger[messageROWID] = chat
            }
        }
    }
}

// MARK: - ChatMessageJoins.swift
public extension DBReader {
    func chatIdentifiers(forMessageGUIDs guids: [String]) -> Promise<[String]> {
        chatRowIDs(forMessageGUIDs: guids).zip { ROWIDs in
            chatIdentifiers(forMessageRowIDs: ROWIDs)
        }.then { ROWIDs, identifiers in
            ROWIDs.compactMap {
                identifiers[$0]
            }
        }
    }
    
    /// Returns the chat id for a message with the given GUID
    /// - Parameter guid: guid of the message to query
    /// - Returns: identifier of the chat the message resides in
    func chatIdentifier(forMessageGUID guid: String) -> Promise<String?> {
        chatRowID(forMessageGUID: guid).maybeMap { ROWID -> Promise<String?> in
            self.chatIdentifier(forMessageRowID: ROWID)
        }
    }
    
    /// Returns the chat id for a message with the given ROWID
    /// - Parameter ROWID: ROWID of the message to query
    /// - Returns: identifier of the chat the message resides in
    func chatIdentifier(forMessageRowID ROWID: Int64) -> Promise<String?> {
        self.chatIdentifiers(forMessageRowIDs: [ROWID]).then {
            $0[ROWID]
        }
    }
    
    /// Resolves the identifiers for chats with the given identifiers
    /// - Parameter ROWIDs: message ROWIDs to resolve
    /// - Returns: ledger of message ROWID to chat identifier
    func chatIdentifiers(forMessageRowIDs ROWIDs: [Int64]) -> Promise<[Int64: String]> {
        partialChats(forMessageRowIDs: ROWIDs, baseColumns: [RawChat.Columns.chat_identifier])
            .compactMapValues(\.chat_identifier)
    }
    
    private func rowIDs(forBeforeMessageGUID beforeMessageGUID: String?, afterMessageGUID: String?) -> Promise<(Int64?, Int64?)> {
        func resolveOne(_ id: String?) -> Promise<Int64?> {
            guard let id = id else {
                return .success(nil)
            }
            
            return rowID(forMessageGUID: id)
        }
        
        switch beforeMessageGUID {
        case .none:
            return resolveOne(afterMessageGUID).then { afterRowID in
                (nil, afterRowID)
            }
        case .some(let beforeMessageGUID):
            guard let afterMessageGUID = afterMessageGUID else {
                return resolveOne(beforeMessageGUID).then { beforeRowID in
                    (beforeRowID, nil)
                }
            }
            
            return rowIDs(forMessageGUIDs: [beforeMessageGUID, afterMessageGUID]).then { identifiers -> (Int64?, Int64?) in
                (identifiers[beforeMessageGUID], identifiers[afterMessageGUID])
            }
        }
    }
    
    /// Resolves the most recent GUIDs for chats with the given ROWIDs
    /// - Parameters:
    ///   - ROWIDs: ROWIDs of the chats to resolve
    ///   - beforeMessageGUID: message GUID to load messages before
    ///   - limit: max number of results to return
    /// - Returns: array of message GUIDs matching the query
    func newestMessageGUIDs(inChatROWIDs ROWIDs: [Int64], beforeDate: Date? = nil, afterDate: Date? = nil, beforeMessageGUID: String? = nil, afterMessageGUID: String? = nil, limit: Int? = nil) -> Promise<[String]> {
        rowIDs(forBeforeMessageGUID: beforeMessageGUID, afterMessageGUID: afterMessageGUID).then { beforeMessageROWID, afterMessageROWID in
            read { db in
                var messageROWIDsQuery = ChatMessageJoin
                    .select(ChatMessageJoin.Columns.message_id, as: Int64.self)
                    .filter(ROWIDs.contains(ChatMessageJoin.Columns.chat_id))
                
                if let beforeMessageROWID = beforeMessageROWID {
                    messageROWIDsQuery = messageROWIDsQuery
                        .filter(ChatMessageJoin.Columns.message_id < beforeMessageROWID)
                }
                
                if let afterMessageROWID = afterMessageROWID {
                    messageROWIDsQuery = messageROWIDsQuery
                        .filter(ChatMessageJoin.Columns.message_id > afterMessageROWID)
                }
                
                if let beforeDate = beforeDate, beforeDate.timeIntervalSinceReferenceDate > 0 {
                    messageROWIDsQuery = messageROWIDsQuery
                        .filter(ChatMessageJoin.Columns.message_date < beforeDate.timeIntervalSinceReferenceDateForDatabase)
                }
                
                if let afterDate = afterDate, afterDate.timeIntervalSinceReferenceDate > 0 {
                    messageROWIDsQuery = messageROWIDsQuery
                        .filter(ChatMessageJoin.Columns.message_date > afterDate.timeIntervalSinceReferenceDateForDatabase)
                }
                
                let messageROWIDs = try messageROWIDsQuery
                    .order(ChatMessageJoin.Columns.message_date.desc)
                    .limit(limit ?? 75)
                    .fetchAll(db)
                
                guard messageROWIDs.count > 0 else {
                    return []
                }
                
                return try RawMessage
                    .select(RawMessage.Columns.guid, as: String.self)
                    .filter(messageROWIDs.contains(RawMessage.Columns.ROWID))
                    .order(RawMessage.Columns.ROWID.desc)
                    .fetchAll(db)
            }
        }
    }
}

private let latestTimestamps = """
SELECT          chat_id, MAX(message_date) AS message_date, chat.guid
FROM            chat_message_join
LEFT JOIN       chat
ON              chat.ROWID = chat_id
GROUP BY        chat_id;
"""

private class TimestampView: GRDB.Record {
    required init(row: Row) {
        chat_id = row["chat_id"]
        message_date = row["message_date"]
        guid = row["guid"]
        super.init(row: row)
    }
    
    var chat_id: Int64
    var message_date: Int64
    var guid: String
}

// MARK: - Latest timestamp API
public extension DBReader {
    typealias RawTimestampView = [Int64: (message_date: Int64, chat_guid: String)]
    
    @_optimize(speed) func latestMessageTimestamps() -> Promise<RawTimestampView> {
        read { database in
            try TimestampView.fetchCursor(database, sql: latestTimestamps)
                .reduce(into: RawTimestampView()) { dictionary, join in
                    dictionary[join.chat_id] = (join.message_date, join.guid)
                }
        }
    }
}
