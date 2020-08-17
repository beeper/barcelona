//
//  GroupTitleChangedItem.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/9/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import Vapor

struct GroupTitleChangeItemRepresentation: Content, ChatItemRepresentation {
    init(_ item: IMGroupTitleChangeItem, chatGroupID: String?) {
        title = item.title
        sender = item.sender
        
        self.load(item: item, chatGroupID: chatGroupID)
    }
    
    init(_ item: IMGroupTitleChangeChatItem, chatGroupID: String?) {
        title = item.title
        sender = (item.handle ?? item.sender)?.id
        
        self.load(item: item, chatGroupID: chatGroupID)
    }
    
    var guid: String?
    var chatGroupID: String?
    var fromMe: Bool?
    var time: Double?
    var title: String?
    var sender: String?
}
