//
//  AcknowledgmentChatItem.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/5/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

import Vapor

struct AcknowledgmentChatItemRepresentation: Content, AssociatedChatItemRepresentation {
    init(_ item: IMMessageAcknowledgmentChatItem, chatGroupID: String?) {
        acknowledgmentType = item.messageAcknowledgmentType
        sender = item.sender?.id
        associatedGUID = item.associatedMessageGUID
        self.load(item: item, chatGroupID: chatGroupID)
    }
    
    var guid: String? = nil
    var chatGroupID: String? = nil
    var fromMe: Bool? = nil
    var time: Double? = nil
    var sender: String?
    var acknowledgmentType: Int64
    var associatedGUID: String
}
