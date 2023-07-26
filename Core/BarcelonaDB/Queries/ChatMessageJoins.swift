//
//  Chats.swift
//  Barcelona
//
//  Created by Eric Rabil on 7/30/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import GRDB

// MARK: - ChatMessageJoins.swift
extension DBReader {
    public func chatIdentifiers(forMessageGUIDs guids: [String]) async throws -> [String] {
        let join: SQLRequest<ChatIdentifierCursor> = """
            SELECT chat.chat_identifier
            FROM message
            LEFT JOIN chat_message_join ON message_id = message.ROWID
            LEFT JOIN chat ON chat.ROWID = chat_message_join.chat_id
            WHERE message.guid IN \(guids)
            """

        return try await read { database in
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
    public func chatIdentifier(forMessageGUID guid: String) async throws -> String? {
        return try await read { database in
            try chatIdentifierQuery(forMessageGUID: guid).fetchOne(database)?.chat_identifier
        }
    }

    public func immediateChatIdentifier(forMessageGUID guid: String) -> String? {
        try? pool.read { database in
            try chatIdentifierQuery(forMessageGUID: guid).fetchOne(database)?.chat_identifier
        }
    }

    /// Resolves the most recent GUIDs for chats with the given ROWIDs
    /// - Parameters:
    ///   - ROWIDs: ROWIDs of the chats to resolve
    ///   - beforeMessageGUID: message GUID to load messages before
    ///   - limit: max number of results to return
    /// - Returns: array of message GUIDs matching the query
    public func newestMessageGUIDs(
        forChatIdentifier chatIdentifier: String,
        onService service: String,
        beforeDate: Date? = nil,
        afterDate: Date? = nil,
        beforeMessageGUID: String? = nil,
        afterMessageGUID: String? = nil,
        limit: Int? = nil
    ) async throws -> [String] {
        try await read { db in
            class MessageGUIDCursor: GRDB.Record {
                required init(row: Row) {
                    guid = row["guid"]
                    super.init(row: row)
                }

                var guid: String
            }

            var sql =
                """
                SELECT message.guid
                FROM message
                INNER JOIN chat_message_join cmj ON cmj.message_id = message.ROWID
                INNER JOIN chat ON cmj.chat_id = chat.ROWID
                WHERE chat.chat_identifier = \(chatIdentifier) AND chat.service_name = \(service)
                """ as SQLLiteral

            if let beforeMessageGUID = beforeMessageGUID {
                sql.append(
                    literal: """
                        AND message.date < (
                            SELECT date FROM message WHERE guid = \(beforeMessageGUID)
                        )
                        """
                )
            }

            if let afterMessageGUID = afterMessageGUID {
                sql.append(
                    literal: """
                        AND message.date > (
                            SELECT date FROM message WHERE guid = \(afterMessageGUID)
                        )
                        """
                )
            }

            if let beforeDate = beforeDate, beforeDate.timeIntervalSinceReferenceDate > 0 {
                sql.append(
                    literal: """
                        AND message.date < \(beforeDate.timeIntervalSinceReferenceDateForDatabase)
                        """
                )
            }

            if let afterDate = afterDate, afterDate.timeIntervalSinceReferenceDate > 0 {
                sql.append(
                    literal: """
                        AND message.date > \(afterDate.timeIntervalSinceReferenceDateForDatabase)
                        """
                )
            }

            sql.append(
                literal: """
                    ORDER BY message.date DESC
                    LIMIT \(limit ?? 75)
                    """
            )

            return try SQLRequest<Row>(literal: sql).fetchAll(db).map { $0["guid"] }
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
extension DBReader {
    public typealias RawTimestampView = [Int64: (message_date: Int64, chat_guid: String)]

    @_optimize(speed) public func latestMessageTimestamps() async throws -> RawTimestampView {
        return try await read { database in
            try TimestampView.fetchCursor(database, sql: latestTimestamps)
                .reduce(into: RawTimestampView()) { dictionary, join in
                    dictionary[join.chat_id] = (join.message_date, join.guid)
                }
        }
    }
}
