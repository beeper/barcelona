//
//  GroupTitleChangedItem.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/9/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

public struct GroupTitleChangeItem: ChatItemRepresentation {
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
    
    public var id: String?
    public var chatID: String?
    public var fromMe: Bool?
    public var time: Double?
    public var title: String?
    public var sender: String?
}
