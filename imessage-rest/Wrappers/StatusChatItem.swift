//
//  StatusChatItem.swift
//  imcore-rest
//
//  Created by Eric Rabil on 7/30/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import Vapor

struct StatusChatItemRepresentation: Content, ChatItemRepresentation {
    init(_ item: IMMessageStatusChatItem, chatGUID: String?) {
        statusType = item.statusType
        itemGUID = item._item().guid
        self.load(item: item, chatGUID: chatGUID)
    }
    
    var guid: String?
    var chatGUID: String?
    var fromMe: Bool?
    var time: Double?
    var statusType: Int64?
    var itemGUID: String
}
