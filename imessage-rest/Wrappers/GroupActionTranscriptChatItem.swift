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
    init(_ item: IMGroupActionChatItem, chatGUID: String?) {
        actionType = item.actionType
        sender = item.sender?.id
        self.load(item: item, chatGUID: chatGUID)
    }
    
    init(_ item: IMGroupActionItem, chatGUID: String?) {
        actionType = item.actionType
        sender = item.sender
        self.load(item: item, chatGUID: chatGUID)
    }
    
    var guid: String?
    var chatGUID: String?
    var fromMe: Bool?
    var time: Double?
    var actionType: Int64
    var sender: String?
}
