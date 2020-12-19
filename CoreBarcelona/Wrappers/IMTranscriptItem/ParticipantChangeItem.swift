//
//  ParticipantChangeChatItem.swift
//  imcore-rest
//
//  Created by Eric Rabil on 7/24/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

public struct ParticipantChangeItem: ChatItemRepresentation {
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
    
    public var id: String?
    public var chatID: String?
    public var fromMe: Bool?
    public var time: Double?
    public var threadIdentifier: String?
    public var threadOriginator: String?
    public var initiatorID: String?
    public var targetID: String?
    public var changeType: Int64
}
