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
        return ERResolveGUIDsForChats(withChatIdentifiers: chatIdentifiers, afterDate: afterDate, beforeDate: beforeDate, afterGUID: afterGUID, beforeGUID: beforeGUID, limit: limit).then { pairs in
            let pairs = Dictionary(uniqueKeysWithValues: pairs)
            return BLLoadIMMessageItems(withGUIDs: Array(pairs.keys)).compactMap {
                guard let chatID = pairs[$0.id] else {
                    return nil
                }
                return (CBChatIdentifier.chatIdentifier(chatID), $0)
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
