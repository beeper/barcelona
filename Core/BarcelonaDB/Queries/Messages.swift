//
//  Messages.swift
//  Barcelona
//
//  Created by Eric Rabil on 7/30/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import BarcelonaFoundation
import Foundation
import GRDB
import Logging

private let logger = Logger(label: "MessagesDB")

// MARK: - Messages.swift
extension DBReader {
    public func chatRowIDs(forMessageGUIDs guids: [String]) async throws -> [Int64] {
        try await read { db in
            try RawMessage
                .select(RawMessage.Columns.ROWID, as: Int64.self)
                .filter(guids.contains(RawMessage.Columns.guid))
                .fetchAll(db)
        }
    }

    /// Returns the chat ROWID for a message with the given GUID
    /// - Parameter guid: guid of the message to query
    /// - Returns: ROWID of the chat the message resides in
    public func chatRowID(forMessageGUID guid: String) async throws -> Int64? {
        try await read { db in
            try RawMessage
                .select(RawMessage.Columns.ROWID, as: Int64.self)
                .filter(RawMessage.Columns.guid == guid)
                .fetchOne(db)
        }
    }

    /// Resolves the ROWID for a message with the given GUID
    /// - Parameter guid: GUID of the message to resolve
    /// - Returns: ROWID of the message
    public func rowID(forMessageGUID guid: String) async throws -> Int64? {
        try await rowIDs(forMessageGUIDs: [guid]).values.first
    }

    public func rowIDs(forMessageGUIDs guids: [String]) async throws -> [String: Int64] {
        try await read { db in
            try RawMessage
                .select(RawMessage.Columns.ROWID, RawMessage.Columns.guid)
                .filter(guids.contains(RawMessage.Columns.guid))
                .fetchAll(db)
                .dictionary(keyedBy: \.guid, valuedBy: \.ROWID)
        }
    }

    public func rawService(forMessage guid: String) -> String? {
        do {
            return try pool.read { database in
                try RawMessage
                    .select(RawMessage.Columns.guid, RawMessage.Columns.service)
                    .filter(RawMessage.Columns.guid == guid)
                    .fetchOne(database)?
                    .service
            }
        } catch {
            logger.error(
                "Failed to query database when fetching the service of IMMessage[guid=\(guid)]: \(String(describing: error))"
            )
            return nil
        }
    }
}
