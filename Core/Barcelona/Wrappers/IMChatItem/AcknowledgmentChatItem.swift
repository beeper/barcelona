//
//  AcknowledgmentChatItem.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/5/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

public struct AcknowledgmentChatItem: ChatItemAssociable, ChatItemOwned, Hashable {
    public static let ingestionClasses: [NSObject.Type] = [IMMessageAcknowledgmentChatItem.self]
    
    public init(ingesting item: NSObject, context: IngestionContext) {
        self.init(item as! IMMessageAcknowledgmentChatItem, chatID: context.chatID)
    }
    
    init(_ item: IMMessageAcknowledgmentChatItem, chatID: String) {
        id = item.id
        self.chatID = chatID
        fromMe = item.isFromMe
        time = item.effectiveTime
        threadIdentifier = item.threadIdentifier
        threadOriginator = item.threadOriginatorID
        acknowledgmentType = item.messageAcknowledgmentType
        sender = item.sender?.id ?? item._item()?.senderID
        associatedID = item.associatedMessageGUID
    }
    
    public var id: String
    public var chatID: String
    public var fromMe: Bool
    public var time: Double
    public var threadIdentifier: String?
    public var threadOriginator: String?
    public var sender: String?
    public var acknowledgmentType: Int64
    public var associatedID: String
    
    public var type: ChatItemType {
        .acknowledgment
    }
}
