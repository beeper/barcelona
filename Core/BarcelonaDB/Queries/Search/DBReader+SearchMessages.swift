//
//  DBReader+SearchMessages.swift
//  Barcelona
//
//  Created by Eric Rabil on 7/30/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import BarcelonaFoundation
import Foundation

/// These extensions are used for the search APIs
extension DBReader {
    public func messages(matching text: String, limit: Int) async throws -> [String] {
        try await read { db in
            try RawMessage
                .select(RawMessage.Columns.guid, as: String.self)
                .filter(RawMessage.Columns.text.uppercased.like("%\(text)%"))
                .order(RawMessage.Columns.date.desc)
                .limit(limit)
                .fetchAll(db)
        }
    }
}
