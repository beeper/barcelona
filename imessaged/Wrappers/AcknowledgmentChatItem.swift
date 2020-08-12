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

struct AcknowledgmentChatItemRepresentation: Content, ChatItemRepresentation {
    init(_ item: IMMessageAcknowledgmentChatItem, chatGUID: String?) {
        acknowledgmentType = item.messageAcknowledgmentType
        sender = item.sender?.id
        self.load(item: item, chatGUID: chatGUID)
    }
    
    var guid: String? = nil
    var chatGUID: String? = nil
    var fromMe: Bool? = nil
    var time: Double? = nil
    var sender: String?
    var acknowledgmentType: Int64
}
