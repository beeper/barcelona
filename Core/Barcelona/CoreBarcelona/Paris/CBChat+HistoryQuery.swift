//
//  CBChat+HistoryQuery.swift
//  Barcelona
//
//  Created by Eric Rabil on 8/8/22.
//

import Foundation

#if canImport(IMSharedUtilities)
import IMSharedUtilities

public extension CBChat {
    func rawHistoryQuery(
        afterDate: Date? = nil,
        beforeDate: Date? = nil,
        afterGUID: String? = nil,
        beforeGUID: String? = nil,
        limit: Int? = nil
    ) async throws -> [(CBChatIdentifier, IMMessageItem)] {
        let guids = try await ERResolveGUIDsForChats(withChatIdentifiers: chatIdentifiers, afterDate: afterDate, beforeDate: beforeDate, afterGUID: afterGUID, beforeGUID: beforeGUID, limit: limit)

        var messageIDMapping: [String: [String]] = [:], messageIDs: Set<String> = Set()
        for (messageID, chatID) in guids {
            messageIDMapping[messageID, default: []].append(chatID)
            messageIDs.insert(messageID)
        }
        return BLLoadIMMessageItems(withGUIDs: Array(messageIDs)).flatMap { message in
            messageIDMapping[message.id, default: []].map { chatID in
                (CBChatIdentifier.chatIdentifier(chatID), message)
            }
        }
    }
    
    func historyQuery(
        afterDate: Date? = nil,
        beforeDate: Date? = nil,
        afterGUID: String? = nil,
        beforeGUID: String? = nil,
        limit: Int? = nil
    ) async throws -> [CBMessage] {
        try await rawHistoryQuery(afterDate: afterDate, beforeDate: beforeDate, afterGUID: afterGUID, beforeGUID: beforeGUID, limit: limit)
            .compactMap(self.handle(leaf:item:))
    }
}
#endif
