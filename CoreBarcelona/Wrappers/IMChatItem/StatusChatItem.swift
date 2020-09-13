//
//  StatusChatItem.swift
//  imcore-rest
//
//  Created by Eric Rabil on 7/30/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

struct StatusChatItem: ChatItemRepresentation {
    init(_ item: IMMessageStatusChatItem, message: IMMessage, chatID: String?) {
        statusType = item.statusType
        itemID = item._item().guid
        flags = Int64(message.flags)
        timeDelivered = (message.timeDelivered?.timeIntervalSince1970 ?? 0) * 1000
        timeRead = (message.timeRead?.timeIntervalSince1970 ?? 0) * 1000
        timePlayed = (message.timePlayed?.timeIntervalSince1970 ?? 0) * 1000
        
        self.load(item: item, chatID: chatID)
    }
    
    var id: String?
    var chatID: String?
    var fromMe: Bool?
    var time: Double?
    var statusType: Int64?
    var itemID: String
    var flags: Int64
    var timeDelivered: Double
    var timeRead: Double
    var timePlayed: Double
}
