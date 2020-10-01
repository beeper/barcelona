//
//  AcknowledgmentChatItem.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/5/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

public struct AcknowledgmentChatItem: AssociatedChatItemRepresentation {
    init(_ item: IMMessageAcknowledgmentChatItem, chatID: String?) {
        acknowledgmentType = item.messageAcknowledgmentType
        sender = item.sender?.id
        associatedID = item.associatedMessageGUID
        self.load(item: item, chatID: chatID)
    }
    
    public var id: String? = nil
    public var chatID: String? = nil
    public var fromMe: Bool? = nil
    public var time: Double? = nil
    public var sender: String?
    public var acknowledgmentType: Int64
    public var associatedID: String
}
