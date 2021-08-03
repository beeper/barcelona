//
//  HandleTimestamps.swift
//  Barcelona
//
//  Created by Eric Rabil on 7/30/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import GRDB

public typealias HandleTimestampRecord = (handle_id: String, date: Int64, chat_id: String)

private class HandleTimestampSynthesized: Record {
    override class var databaseTableName: String { "chat_message_join" }
    
    required init(row: Row) {
        handle_id = row[Columns.handle_id]
        chat_id = row[Columns.chat_id]
        date = row[Columns.date]
        super.init(row: row)
    }
    
    enum Columns: String, ColumnExpression {
        case handle_id, chat_id, date
    }
    
    var handle_id: String
    var chat_id: String
    var date: Int64
    
    /// Tuple used when sorting an array of handles for a chat
    var record: HandleTimestampRecord {
        (handle_id: handle_id, date: date, chat_id: chat_id)
    }
    
}

private extension Array where Element == HandleTimestampSynthesized {
    var records: [HandleTimestampRecord] {
        map {
            $0.record
        }
    }
}

public extension DBReader {
    /// Returns an arrya of handle/timestamp records used for sorting an array of chat participants
    /// - Parameter chatIDs: identifiers of the chats to pull participants for (typically this should just be identifiers for the same chat on different services)
    /// - Returns: array of handle/timestamp pairs
    func handleTimestampRecords(forChatIdentifiers chatIDs: [String]) -> Promise<[HandleTimestampRecord]> {
        read { db in
            let queryFinished = Logging.Database.signpost("Query time-sorted participants")
            
            let stmt = try db.makeSelectStatement(sql:
"""
SELECT DISTINCT handle.id AS handle_id, MAX(message.date) AS date, chat.chat_identifier AS chat_id FROM message
INNER JOIN handle ON message.handle_id = handle.ROWID
INNER JOIN chat_message_join ON message.ROWID = chat_message_join.message_id
INNER JOIN chat ON chat_message_join.chat_id = chat.ROWID AND chat.chat_identifier IN (\(chatIDs.templatedString))  GROUP BY handle_id, chat_identifier ORDER BY message.date DESC
""")
            
            try stmt.setArguments(StatementArguments(chatIDs))
            let results = try HandleTimestampSynthesized.fetchCursor(stmt).map(\.record)
            
            queryFinished()
            
            return try Array(results)
        }
    }
}
