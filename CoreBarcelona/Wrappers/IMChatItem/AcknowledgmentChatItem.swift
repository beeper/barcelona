//
//  AcknowledgmentChatItem.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/5/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

struct AcknowledgmentChatItem: AssociatedChatItemRepresentation {
    init(_ item: IMMessageAcknowledgmentChatItem, chatID: String?) {
        acknowledgmentType = item.messageAcknowledgmentType
        sender = item.sender?.id
        associatedID = item.associatedMessageGUID
        self.load(item: item, chatID: chatID)
    }
    
    var id: String? = nil
    var chatID: String? = nil
    var fromMe: Bool? = nil
    var time: Double? = nil
    var sender: String?
    var acknowledgmentType: Int64
    var associatedID: String
}
