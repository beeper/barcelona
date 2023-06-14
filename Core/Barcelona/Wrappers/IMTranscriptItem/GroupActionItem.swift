//
//  GroupActionChatItem.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/2/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

extension IMGroupActionType: Codable {

}

public struct GroupActionItem: ChatItemOwned, Hashable {
    public static let ingestionClasses: [NSObject.Type] = [IMGroupActionChatItem.self, IMGroupActionItem.self]

    public init?(ingesting item: NSObject, context: IngestionContext) {
        switch item {
        case let item as IMGroupActionChatItem:
            self.init(item, chatID: context.chatID, service: context.service)
        case let item as IMGroupActionItem:
            self.init(item, chatID: context.chatID, service: context.service)
        default:
            return nil
        }
    }

    init(_ item: IMGroupActionChatItem, chatID: String, service: IMServiceStyle) {
        id = item.id
        self.chatID = chatID
        fromMe = item.isFromMe
        time = item.effectiveTime
        actionType = item.actionType
        sender = item._item().resolveSenderID(inService: service)
        threadIdentifier = item.threadIdentifier
        threadOriginator = item.threadOriginatorID
    }

    init(_ item: IMGroupActionItem, chatID: String, service: IMServiceStyle) {
        id = item.id
        self.chatID = chatID
        fromMe = item.isFromMe
        time = item.effectiveTime
        actionType = item.actionType
        sender = item.resolveSenderID(inService: service)
        threadIdentifier = item.threadIdentifier
        threadOriginator = item.threadOriginatorID
    }

    public var id: String
    public var chatID: String
    public var fromMe: Bool
    public var time: Double
    public var threadIdentifier: String?
    public var threadOriginator: String?
    public var actionType: IMGroupActionType
    public var sender: String?

    public var type: ChatItemType {
        .groupAction
    }
}
