//
//  Messages.swift
//  Barcelona
//
//  Created by Eric Rabil on 7/30/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import BarcelonaFoundation
import GRDB

// MARK: - Messages.swift
public extension DBReader {
    func chatRowIDs(forMessageGUIDs guids: [String]) -> Promise<[Int64]> {
        read { db in
            try RawMessage
                .select(RawMessage.Columns.ROWID, as: Int64.self)
                .filter(guids.contains(RawMessage.Columns.guid))
                .fetchAll(db)
        }
    }
    
    /// Returns the chat ROWID for a message with the given GUID
    /// - Parameter guid: guid of the message to query
    /// - Returns: ROWID of the chat the message resides in
    func chatRowID(forMessageGUID guid: String) -> Promise<Int64?> {
        read { db in
            try RawMessage
                .select(RawMessage.Columns.ROWID, as: Int64.self)
                .filter(RawMessage.Columns.guid == guid)
                .fetchOne(db)
        }
    }
    
    /// Resolves the ROWID for a message with the given GUID
    /// - Parameter guid: GUID of the message to resolve
    /// - Returns: ROWID of the message
    func rowID(forMessageGUID guid: String) -> Promise<Int64?> {
        rowIDs(forMessageGUIDs: [guid]).values.first
    }
    
    func rowIDs(forMessageGUIDs guids: [String]) -> Promise<[String: Int64]> {
        read { db in
            try RawMessage
                .select(RawMessage.Columns.ROWID, RawMessage.Columns.guid)
                .filter(guids.contains(RawMessage.Columns.guid))
                .fetchAll(db)
                .dictionary(keyedBy: \.guid, valuedBy: \.ROWID)
        }
    }
}
