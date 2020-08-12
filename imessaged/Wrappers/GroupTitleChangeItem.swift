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
    init(_ item: IMGroupTitleChangeItem, chatGUID: String?) {
        title = item.title
        sender = item.sender
        
        self.load(item: item, chatGUID: chatGUID)
    }
    
    init(_ item: IMGroupTitleChangeChatItem, chatGUID: String?) {
        title = item.title
        sender = (item.handle ?? item.sender)?.id
        
        self.load(item: item, chatGUID: chatGUID)
    }
    
    var guid: String?
    var chatGUID: String?
    var fromMe: Bool?
    var time: Double?
    var title: String
    var sender: String?
}
