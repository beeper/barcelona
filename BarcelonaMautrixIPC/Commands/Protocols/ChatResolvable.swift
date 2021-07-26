//
//  ChatResolvable.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 5/24/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import Barcelona
import IMCore

public protocol ChatResolvable {
    var chat_guid: String { get set }
}

public extension ChatResolvable {
    var chat: IMChat? {
        IMChatRegistry.shared.existingChat(withGUID: chat_guid)
    }
    
    var cbChat: Chat? {
        guard let chat = chat else {
            return nil
        }
        
        return Chat(chat)
    }
    
    var blChat: BLChat? {
        chat?.blChat
    }
}
