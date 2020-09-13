//
//  ParticipantChangeChatItem.swift
//  imcore-rest
//
//  Created by Eric Rabil on 7/24/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

struct ParticipantChangeItem: ChatItemRepresentation {
    init(_ item: IMParticipantChangeChatItem, chatID: String?) {
        initiatorID = item.sender?.id
        targetID = item.otherHandle?.id
        changeType = item.changeType
        self.load(item: item, chatID: chatID)
    }
    
    init(_ item: IMParticipantChangeItem, chatID: String?) {
        initiatorID = item.sender
        targetID = item.otherHandle
        changeType = item.changeType
        self.load(item: item, chatID: chatID)
    }
    
    var id: String?
    var chatID: String?
    var fromMe: Bool?
    var time: Double?
    var initiatorID: String?
    var targetID: String?
    var changeType: Int64
}
