//
//  GroupTitleChangedItem.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/9/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

public protocol IMGroupTitleItemConforming: IMCoreDataResolvable {
    var title: String! { get }
    var senderID: String? { get }
}

extension IMGroupTitleItemConforming {
    var resolvedSenderID: String? {
        switch self {
        case let item as IMChatItem: return item.resolvedSenderID
        case let item as IMItem: return item.resolveSenderID()
        default: return senderID
        }
    }
}

extension IMGroupTitleChangeItem: IMGroupTitleItemConforming {}
extension IMGroupTitleChangeChatItem: IMGroupTitleItemConforming {
    public var senderID: String? {
        (handle ?? sender)?.id
    }
}

public struct GroupTitleChangeItem: ChatItemOwned, Hashable {
    public static let ingestionClasses: [NSObject.Type] = [IMGroupTitleChangeItem.self, IMGroupTitleChangeChatItem.self]
    
    public init?(ingesting item: NSObject, context: IngestionContext) {
        switch item {
        case let item as IMGroupTitleChangeItem:
            self.init(item, chatID: context.chatID)
        case let item as IMGroupTitleChangeChatItem:
            self.init(item, chatID: context.chatID)
        default:
            return nil
        }
    }
    
    init(_ item: IMGroupTitleItemConforming, chatID: String) {
        id = item.id
        self.chatID = chatID
        fromMe = item.isFromMe
        time = item.effectiveTime
        title = item.title
        sender = item.resolvedSenderID
        threadIdentifier = item.threadIdentifier
        threadOriginator = item.threadOriginatorID
    }
    
    public var id: String
    public var chatID: String
    public var fromMe: Bool
    public var time: Double
    public var threadIdentifier: String?
    public var threadOriginator: String?
    public var title: String?
    public var sender: String?
    
    public var type: ChatItemType {
        .groupTitle
    }
}
