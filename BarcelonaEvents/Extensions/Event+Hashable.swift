//
//  Event+Hashable.swift
//  BarcelonaEvents
//
//  Created by Eric Rabil on 7/26/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import Barcelona

extension Event: Hashable {
    public var hashableValue: AnyHashable {
        switch self {
        case .bootstrap(let item):
            return AnyHashable(item)
        case .itemsReceived(let item):
            return AnyHashable(item)
        case .itemsUpdated(let item):
            return AnyHashable(item)
        case .itemStatusChanged(let item):
            return AnyHashable(item)
        case .itemsRemoved(let item):
            return AnyHashable(item)
        case .participantsChanged(let item):
            return AnyHashable(item)
        case .conversationRemoved(let item):
            return AnyHashable(item)
        case .conversationCreated(let item):
            return AnyHashable(item)
        case .conversationChanged(let item):
            return AnyHashable(item)
        case .conversationDisplayNameChanged(let item):
            return AnyHashable(item)
        case .conversationJoinStateChanged(let item):
            return AnyHashable(item)
        case .conversationUnreadCountChanged(let item):
            return AnyHashable(item)
        case .conversationPropertiesChanged(let item):
            return AnyHashable(item)
        case .contactCreated(let item):
            return AnyHashable(item)
        case .contactRemoved(let item):
            return AnyHashable(item)
        case .contactUpdated(let item):
            return AnyHashable(item)
        case .blockListUpdated(let item):
            return AnyHashable(item)
        }
    }
    
    public static func == (lhs: Event, rhs: Event) -> Bool {
        lhs.hashableValue == rhs.hashableValue
    }
    
    public func hash(into hasher: inout Hasher) {
        hashableValue.hash(into: &hasher)
    }
}
