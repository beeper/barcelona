//
//  ActionChatItem.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/3/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

struct ActionChatItem: ChatItemRepresentation {
    init(_ item: IMMessageActionItem, chat: String) {
        actionType = item.actionType
        sender = item.sender
        otherHandle = item.otherHandle
        
        load(item: item, chatID: chat)
    }
    
    init(_ item: IMMessageActionChatItem, chat: String) {
        actionType = item.actionType
        sender = item.sender?.id
        otherHandle = item.otherHandle?.id
        
        load(item: item, chatID: chat)
    }
    
    var id: String?
    var chatID: String?
    var fromMe: Bool?
    var time: Double?
    var sender: String?
    var otherHandle: String?
    var actionType: Int64
}
