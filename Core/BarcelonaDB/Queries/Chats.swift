//
//  Chats.swift
//  Barcelona
//
//  Created by Eric Rabil on 7/30/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import BarcelonaFoundation

public extension DBReader {
    /// Returns the ROWiDs for a chat with the given identifier
    /// - Parameter identifier: identifier of the chat to resolve
    /// - Returns: array of ROWIDs
    func rowIDs(forIdentifier identifier: String) async throws -> [Int64] {
        let rowIds = try await rowIDs(forIdentifiers: [identifier])
        return rowIds[identifier] ?? []
    }
    
    /// Resolves all ROWIDs for all chat identifiers
    /// - Parameter identifiers: chat identifiers to resolve
    /// - Returns: dictionary of chat identifier to ROWIDs
    func rowIDs(forIdentifiers identifiers: [String]) async throws -> [String: [Int64]] {
        try await read { db in
            try RawChat
                .select([RawChat.Columns.ROWID, RawChat.Columns.chat_identifier])
                .filter(identifiers.contains(RawChat.Columns.chat_identifier))
                .fetchAll(db)
        }.collectedDictionary(keyedBy: \.chat_identifier, valuedBy: \.ROWID)
    }
}
