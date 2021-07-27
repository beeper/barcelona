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
}

extension IMMessageActionItem: IMMessageActionItemParseable {
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

public struct ActionChatItem: ChatItemOwned, Hashable {
    public static let ingestionClasses: [NSObject.Type] = [IMMessageActionItem.self, IMMessageActionChatItem.self]
    
    public init?(ingesting item: NSObject, context: IngestionContext) {
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
        sender = item.senderID
        otherHandle = item.otherHandleID
    }
    
    public var id: String
    public var chatID: String
    public var fromMe: Bool
    public var time: Double
    public var threadIdentifier: String?
    public var threadOriginator: String?
    public var sender: String?
    public var otherHandle: String?
    public var actionType: Int64
    
    public var type: ChatItemType {
        .action
    }
}
