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
    func rawHistoryQuery(afterDate: Date? = nil, beforeDate: Date? = nil, afterGUID: String? = nil, beforeGUID: String? = nil, limit: Int? = nil) -> Promise<[(CBChatIdentifier, IMMessageItem)]> {
        return ERResolveGUIDsForChats(withChatIdentifiers: chatIdentifiers, afterDate: afterDate, beforeDate: beforeDate, afterGUID: afterGUID, beforeGUID: beforeGUID, limit: limit).then {
            var messageIDMapping: [String: [String]] = [:], messageIDs: Set<String> = Set()
            for (messageID, chatID) in $0 {
                messageIDMapping[messageID, default: []].append(chatID)
                messageIDs.insert(messageID)
            }
            return BLLoadIMMessageItems(withGUIDs: Array(messageIDs)).flatMap { message in
                messageIDMapping[message.id, default: []].map { chatID in
                    (CBChatIdentifier.chatIdentifier(chatID), message)
                }
            }
        }
    }
    
    func historyQuery(afterDate: Date? = nil, beforeDate: Date? = nil, afterGUID: String? = nil, beforeGUID: String? = nil, limit: Int? = nil) -> Promise<[CBMessage]> {
        rawHistoryQuery(afterDate: afterDate, beforeDate: beforeDate, afterGUID: afterGUID, beforeGUID: beforeGUID, limit: limit).then { items in
            items.compactMap(self.handle(leaf:item:))
        }
    }
}
#endif
