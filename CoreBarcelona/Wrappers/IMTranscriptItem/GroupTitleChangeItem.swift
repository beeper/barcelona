//
//  GroupTitleChangedItem.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/9/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

struct GroupTitleChangeItem: ChatItemRepresentation {
    init(_ item: IMGroupTitleChangeItem, chatID: String?) {
        title = item.title
        sender = item.sender
        
        self.load(item: item, chatID: chatID)
    }
    
    init(_ item: IMGroupTitleChangeChatItem, chatID: String?) {
        title = item.title
        sender = (item.handle ?? item.sender)?.id
        
        self.load(item: item, chatID: chatID)
    }
    
    var id: String?
    var chatID: String?
    var fromMe: Bool?
    var time: Double?
    var title: String?
    var sender: String?
}
