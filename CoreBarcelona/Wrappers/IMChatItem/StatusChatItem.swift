//
//  StatusChatItem.swift
//  imcore-rest
//
//  Created by Eric Rabil on 7/30/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

public struct StatusChatItem: ChatItemRepresentation {
    init(_ item: IMMessageStatusChatItem, message: IMMessage, chatID: String?) {
        statusType = item.statusType
        itemID = item._item().guid
        
        self.load(item: item, chatID: chatID)
    }
    
    public var id: String?
    public var chatID: String?
    public var fromMe: Bool?
    public var time: Double?
    public var threadIdentifier: String?
    public var threadOriginator: String?
    public var statusType: Int64?
    public var itemID: String
}
