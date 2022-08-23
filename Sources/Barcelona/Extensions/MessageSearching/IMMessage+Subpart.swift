//
//  IMMessage+RetrieveSubpart.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/5/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import IMSharedUtilities

public extension IMMessageItem {
    var chatItems: [IMChatItem] {
        let items = _newChatItems()
        
        switch items {
        case let items as [IMChatItem]:
            return items
        case let item as IMChatItem:
            return [item]
        default:
            return []
        }
    }
}

extension IMMessage {
    /**
     Returns a single subpart from a message
     */
    func subpart(at index: Int) -> IMChatItem? {
        guard let parts = _imMessageItem?.chatItems else { return nil }
        if (parts.count - 1) < index { return nil }
        
        return parts[index]
    }
    
    func subpart(with guid: String) -> IMChatItem? {
        _imMessageItem?.chatItems.first(where: {
            guard let part = $0 as? IMMessagePartChatItem else {
                return false
            }
            return part.guid == guid
        })
    }
}
