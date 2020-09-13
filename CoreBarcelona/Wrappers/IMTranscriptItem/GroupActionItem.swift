//
//  GroupActionChatItem.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/2/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

struct GroupActionItem: ChatItemRepresentation {
    init(_ item: IMGroupActionChatItem, chatID: String?) {
        actionType = item.actionType
        sender = item.sender?.id
        self.load(item: item, chatID: chatID)
    }
    
    init(_ item: IMGroupActionItem, chatID: String?) {
        actionType = item.actionType
        sender = item.sender
        self.load(item: item, chatID: chatID)
    }
    
    var id: String?
    var chatID: String?
    var fromMe: Bool?
    var time: Double?
    var actionType: Int64
    var sender: String?
    
}
