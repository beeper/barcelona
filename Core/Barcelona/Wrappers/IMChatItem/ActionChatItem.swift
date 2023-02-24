//
//  ActionChatItem.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/3/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

protocol IMMessageActionItemParseable: IMCoreDataResolvable {
    var actionType: Int64 { get }
    var senderID: String? { get }
    var otherHandleID: String? { get }
    var resolvedSenderID: String? { get }
}

extension IMMessageActionItem: IMMessageActionItemParseable {
    var resolvedSenderID: String? {
        resolveSenderID()
    }

    var otherHandleID: String? {
        otherHandle
    }
}

extension IMMessageActionChatItem: IMMessageActionItemParseable {
    var senderID: String? {
        sender?.id
    }

    var otherHandleID: String? {
        otherHandle?.id
    }
}

struct ActionChatItem: ChatItemOwned, Hashable {
    static let ingestionClasses: [NSObject.Type] = [IMMessageActionItem.self, IMMessageActionChatItem.self]

    init?(ingesting item: NSObject, context: IngestionContext) {
        switch item {
        case let item as IMMessageActionItem:
            self.init(item, chat: context.chatID)
        case let item as IMMessageActionChatItem:
            self.init(item, chat: context.chatID)
        default:
            return nil
        }
    }

    init(_ item: IMMessageActionItemParseable, chat: String) {
        id = item.id
        chatID = chat
        fromMe = item.isFromMe
        time = item.effectiveTime
        threadIdentifier = item.threadIdentifier
        threadOriginator = item.threadOriginatorID
        actionType = item.actionType
        sender = item.resolvedSenderID
        otherHandle = item.otherHandleID
    }

    var id: String
    var chatID: String
    var fromMe: Bool
    var time: Double
    var threadIdentifier: String?
    var threadOriginator: String?
    var sender: String?
    var otherHandle: String?
    var actionType: Int64

    var type: ChatItemType {
        .action
    }
}
