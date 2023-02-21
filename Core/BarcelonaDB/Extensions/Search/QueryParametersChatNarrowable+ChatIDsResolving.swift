//
//  QueryParametersChatNarrowable+ChatIDsResolving.swift
//  Barcelona
//
//  Created by Eric Rabil on 7/30/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import BarcelonaFoundation
import Foundation

extension QueryParametersChatNarrowable {
    func chatROWIDs() async throws -> [Int64] {
        guard let chats, !chats.isEmpty else {
            return []
        }

        return try await DBReader.shared.rowIDs(forIdentifiers: chats).values.flatten()
    }
}
