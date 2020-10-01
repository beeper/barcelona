//
//  ActionChatItem.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/3/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

public struct ActionChatItem: ChatItemRepresentation {
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
    
    public var id: String?
    public var chatID: String?
    public var fromMe: Bool?
    public var time: Double?
    public var sender: String?
    public var otherHandle: String?
    public var actionType: Int64
}
