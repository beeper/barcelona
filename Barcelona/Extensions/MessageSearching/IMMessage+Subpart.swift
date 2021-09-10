//
//  IMMessage+RetrieveSubpart.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/5/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

extension IMMessage {
    /**
     Returns a single subpart from a message
     */
    func subpart(at index: Int, inChat chat: IMChat) -> IMChatItem? {
        guard let _imMessageItem = _imMessageItem, let parts = chat.chatItems(for: [_imMessageItem]) else { return nil }
        if (parts.count - 1) < index { return nil }
        
        return parts[index]
    }
    
    func subpart(with guid: String, inChat chat: IMChat) -> IMChatItem? {
        guard let _imMessageItem = _imMessageItem, let parts = chat.chatItems(for: [_imMessageItem]) else { return nil }
        return parts.first(where: {
            guard let part = $0 as? IMMessagePartChatItem else {
                return false
            }
            return part.guid == guid
        })
    }
}
