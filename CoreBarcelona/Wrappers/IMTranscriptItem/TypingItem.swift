//
//  TypingChatItemRepresentation.swift
//  imessage-rest
//
//  Created by Eric Rabil on 8/12/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

struct TypingItem: ChatItemRepresentation {
    init(_ item: IMTypingChatItem, chatID: String?) {
        sender = item.sender?.id
        
        self.load(item: item, chatID: chatID)
    }
    
    var id: String?
    var chatID: String?
    var fromMe: Bool?
    var time: Double?
    var sender: String?
}
