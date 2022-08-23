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

// MARK: - ChatMessageJoins.swift
public extension DBReader {
    func chatIdentifiers(forMessageGUIDs guids: [String]) -> Promise<[String]> {
        let join: SQLRequest<ChatIdentifierCursor> = """
        SELECT chat.chat_identifier
        FROM message
        LEFT JOIN chat_message_join ON message_id = message.ROWID
        LEFT JOIN chat ON chat.ROWID = chat_message_join.chat_id
        WHERE message.guid IN \(guids)
        """
        
        return read { database in
            try join.fetchAll(database).map(\.chat_identifier)
        }
    }
    
    private class ChatIdentifierCursor: GRDB.Record {
        required init(row: Row) {
            chat_identifier = row["chat_identifier"]
            super.init(row: row)
        }
        
        var chat_identifier: String
    }
    
    private func chatIdentifierQuery(forMessageGUID guid: String) -> SQLRequest<ChatIdentifierCursor> {
        """
        SELECT chat.chat_identifier from message
        JOIN chat_message_join ON chat_message_join.message_id = message.ROWID
        JOIN chat ON chat.ROWID = chat_message_join.chat_id
        WHERE message.guid = \(guid)
        LIMIT 1;
        """
    }
    
    /// Returns the chat id for a message with the given GUID
    /// - Parameter guid: guid of the message to query
    /// - Returns: identifier of the chat the message resides in
    func chatIdentifier(forMessageGUID guid: String) -> Promise<String?> {
        return read { database in
            try chatIdentifierQuery(forMessageGUID: guid).fetchOne(database)?.chat_identifier
        }
    }
    
    @_spi(synchronousQueries) func immediateChatIdentifier(forMessageGUID guid: String) -> String? {
        try? pool.read { database in
            try chatIdentifierQuery(forMessageGUID: guid).fetchOne(database)?.chat_identifier
        }
    }
    
    /// Returns the chat id for a message with the given ROWID
    /// - Parameter ROWID: ROWID of the message to query
    /// - Returns: identifier of the chat the message resides in
    func chatIdentifier(forMessageRowID ROWID: Int64) -> Promise<String?> {
        let join: SQLRequest<ChatIdentifierCursor> = """
        SELECT chat.chat_identifier from message
        LEFT JOIN chat_message_join ON chat_message_join.message_id = message.ROWID
        LEFT JOIN chat ON chat.ROWID = chat_message_join.chat_id
        WHERE message.ROWID = \(ROWID)
        LIMIT 1;
        """
        
        return read { database in
            try join.fetchOne(database)?.chat_identifier
        }
    }
    
    private class MessageChatIdentifierCursor: GRDB.Record {
        required init(row: Row) {
            message_id = row["message_id"]
            chat_identifier = row["chat_identifier"]
            super.init(row: row)
        }
        
        var message_id: Int64
        var chat_identifier: String
    }
    
    /// Resolves the identifiers for chats with the given identifiers
    /// - Parameter ROWIDs: message ROWIDs to resolve
    /// - Returns: ledger of message ROWID to chat identifier
    func chatIdentifiers(forMessageRowIDs ROWIDs: [Int64]) -> Promise<[Int64: String]> {
        let join: SQLRequest<MessageChatIdentifierCursor> = """
        SELECT message.ROWID AS message_id, chat.chat_identifier from message
        LEFT JOIN chat_message_join ON chat_message_join.message_id = message.ROWID
        LEFT JOIN chat ON chat.ROWID = chat_message_join.chat_id
        WHERE message.ROWID IN \(ROWIDs);
        """
        
        return read { database in
            try join.fetchAll(database).reduce(into: [Int64: String]()) { dict, join in
                dict[join.message_id] = join.chat_identifier
            }
        }
    }
    
    /// Resolves the most recent GUIDs for chats with the given ROWIDs
    /// - Parameters:
    ///   - ROWIDs: ROWIDs of the chats to resolve
    ///   - beforeMessageGUID: message GUID to load messages before
    ///   - limit: max number of results to return
    /// - Returns: array of message GUIDs matching the query
    func newestMessageGUIDs(forChatIdentifiers chatIdentifiers: [String], beforeDate: Date? = nil, afterDate: Date? = nil, beforeMessageGUID: String? = nil, afterMessageGUID: String? = nil, limit: Int? = nil) -> Promise<[(messageID: String, chatID: String)]> {
        read { db in
            class MessageGUIDCursor: GRDB.Record {
                required init(row: Row) {
                    guid = row["guid"]
                    super.init(row: row)
                }
                
                var guid: String
            }
            
            var sql = """
            SELECT message.guid, chat.chat_identifier
            FROM message
            INNER JOIN chat_message_join cmj ON cmj.message_id = message.ROWID
            INNER JOIN chat ON cmj.chat_id = chat.ROWID
            WHERE chat.chat_identifier IN \(chatIdentifiers)
            """ as SQLLiteral
            
            if let beforeMessageGUID = beforeMessageGUID {
                sql.append(literal: """
                AND message.date < (
                    SELECT date FROM message WHERE guid = \(beforeMessageGUID)
                )
                """)
            }
            
            if let afterMessageGUID = afterMessageGUID {
                sql.append(literal: """
                AND message.date > (
                    SELECT date FROM message WHERE guid = \(afterMessageGUID)
                )
                """)
            }
            
            if let beforeDate = beforeDate, beforeDate.timeIntervalSinceReferenceDate > 0 {
                sql.append(literal: """
                AND message.date < \(beforeDate.timeIntervalSinceReferenceDateForDatabase)
                """)
            }
            
            if let afterDate = afterDate, afterDate.timeIntervalSinceReferenceDate > 0 {
                sql.append(literal: """
                AND message.date > \(afterDate.timeIntervalSinceReferenceDateForDatabase)
                """)
            }
            
            sql.append(literal: """
            ORDER BY message.date DESC
            LIMIT \(limit ?? 75)
            """)
            
            return try SQLRequest<Row>(literal: sql).fetchAll(db).map { ($0["guid"], $0["chat_identifier"]) }
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
