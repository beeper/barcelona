//
//  AcknowledgmentChatItem.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/5/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import Logging

extension IMChatItem {
    var resolvedSenderID: String? {
        _item().resolveSenderID()
    }
}

private let log = Logger(label: "AcknowledgmentChatItem")

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
        acknowledgmentType = item.acknowledmentType
        if acknowledgmentType == 0 {
            log.debug(
                "tapback is nil for id \(id) on ventura; this is very unexpected",
                source: "AcknowledgmentChatItem"
            )
        }
        sender = item.resolvedSenderID
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

extension IMMessageAcknowledgmentChatItem {
    public var acknowledmentType: Int64 {
        if #available(macOS 13, *) {
            return tapback?.associatedMessageType ?? 0
        } else {
            return messageAcknowledgmentType
        }
    }
}
