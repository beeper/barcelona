//
//  Tapbacks.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/7/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import BarcelonaFoundation
import Foundation

extension DBReader {
    /// Loads messages associated with the given GUIDs
    /// - Parameters:
    ///   - guids: GUIDs of messages to resolve associations
    ///   - chat: ID of the chat the messages reside in. if omitted, they will be resolved at ingestion
    /// - Returns: Dictionary of GUIDs from the guids parameter to an array of associated messages
    public func associatedMessageGUIDs(with guids: [String]) async throws -> [String: [String]] {
        if guids.count == 0 { return [:] }

        return try await read { db in
            try RawMessage
                .select(RawMessage.Columns.guid, RawMessage.Columns.associated_message_guid, RawMessage.Columns.ROWID)
                .filter(guids.contains(RawMessage.Columns.associated_message_guid))
                .fetchAll(db)
        }
        .collectedDictionary(keyedBy: \.associated_message_guid, valuedBy: \.guid)
    }
}
