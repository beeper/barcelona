//
//  ParticipantChangeChatItem.swift
//  imcore-rest
//
//  Created by Eric Rabil on 7/24/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import Vapor

struct ParticipantChangeTranscriptChatItemRepresentation: Content, ChatItemRepresentation {
    init(_ item: IMParticipantChangeChatItem, chatGroupID: String?) {
        initiatorID = item.sender?.id
        targetID = item.otherHandle?.id
        changeType = item.changeType
        self.load(item: item, chatGroupID: chatGroupID)
    }
    
    init(_ item: IMParticipantChangeItem, chatGroupID: String?) {
        initiatorID = item.sender
        targetID = item.otherHandle
        changeType = item.changeType
        self.load(item: item, chatGroupID: chatGroupID)
    }
    
    var guid: String?
    var chatGroupID: String?
    var fromMe: Bool?
    var time: Double?
    var initiatorID: String?
    var targetID: String?
    var changeType: Int64
}
