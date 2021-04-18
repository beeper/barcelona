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
        sender = item.sender?.id ?? item._item()?.senderID
        associatedID = item.associatedMessageGUID
        self.load(item: item, chatID: chatID)
    }
    
    public var id: String?
    public var chatID: String?
    public var fromMe: Bool?
    public var time: Double?
    public var threadIdentifier: String?
    public var threadOriginator: String?
    public var sender: String?
    public var acknowledgmentType: Int64
    public var associatedID: String
}
