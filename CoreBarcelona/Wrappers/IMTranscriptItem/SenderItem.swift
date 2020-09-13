//
//  SenderChatItem.swift
//  imcore-rest
//
//  Created by Eric Rabil on 7/24/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

struct SenderItem: ChatItemRepresentation {
    init(_ item: IMSenderChatItem, chatID chat: String?) {
        handleID = item.handle.id
        self.load(item: item, chatID: chat)
    }
    
    var id: String?
    var chatID: String?
    var fromMe: Bool?
    var time: Double?
    var handleID: String
}
