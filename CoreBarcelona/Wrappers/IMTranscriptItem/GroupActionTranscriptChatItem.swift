//
//  GroupActionChatItem.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/2/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import Vapor

struct GroupActionTranscriptChatItemRepresentation: Content, ChatItemRepresentation {
    init(_ item: IMGroupActionChatItem, chatGroupID: String?) {
        actionType = item.actionType
        sender = item.sender?.id
        self.load(item: item, chatGroupID: chatGroupID)
    }
    
    init(_ item: IMGroupActionItem, chatGroupID: String?) {
        actionType = item.actionType
        sender = item.sender
        self.load(item: item, chatGroupID: chatGroupID)
    }
    
    var guid: String?
    var chatGroupID: String?
    var fromMe: Bool?
    var time: Double?
    var actionType: Int64
    var sender: String?
    
}
