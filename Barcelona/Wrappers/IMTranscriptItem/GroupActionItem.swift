//
//  GroupActionChatItem.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/2/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

public struct GroupActionItem: ChatItemOwned, Hashable {
    public static let ingestionClasses: [NSObject.Type] = [IMGroupActionChatItem.self, IMGroupActionItem.self]
    
    public init?(ingesting item: NSObject, context: IngestionContext) {
        switch item {
        case let item as IMGroupActionChatItem:
            self.init(item, chatID: context.chatID)
        case let item as IMGroupActionItem:
            self.init(item, chatID: context.chatID)
        default:
            return nil
        }
    }
    
    init(_ item: IMGroupActionChatItem, chatID: String?) {
        actionType = item.actionType
        sender = item.sender?.id
        self.load(item: item, chatID: chatID)
    }
    
    init(_ item: IMGroupActionItem, chatID: String?) {
        actionType = item.actionType
        sender = item.sender
        self.load(item: item, chatID: chatID)
    }
    
    public var id: String?
    public var chatID: String?
    public var fromMe: Bool?
    public var time: Double?
    public var threadIdentifier: String?
    public var threadOriginator: String?
    public var actionType: Int64
    public var sender: String?
    
    public var type: ChatItemType {
        .groupAction
    }
}
