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
    init(_ item: IMMessageStatusChatItem, message: IMMessage, chatGroupID: String?) {
        statusType = item.statusType
        itemGUID = item._item().guid
        flags = Int64(message.flags)
        timeDelivered = (message.timeDelivered?.timeIntervalSince1970 ?? 0) * 1000
        timeRead = (message.timeRead?.timeIntervalSince1970 ?? 0) * 1000
        timePlayed = (message.timePlayed?.timeIntervalSince1970 ?? 0) * 1000
        
        self.load(item: item, chatGroupID: chatGroupID)
    }
    
    var guid: String?
    var chatGroupID: String?
    var fromMe: Bool?
    var time: Double?
    var statusType: Int64?
    var itemGUID: String
    var flags: Int64
    var timeDelivered: Double
    var timeRead: Double
    var timePlayed: Double
}
