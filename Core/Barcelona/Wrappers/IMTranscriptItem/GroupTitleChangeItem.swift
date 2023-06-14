//
//  GroupTitleChangedItem.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/9/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import IMSharedUtilities

protocol IMGroupTitleItemConforming: IMCoreDataResolvable {
    var title: String! { get }
    var item: IMItem { get }
}

extension IMGroupTitleItemConforming {
    func resolveSenderID(inService service: IMServiceStyle) -> String? {
        item.resolveSenderID(inService: service)
    }
}

extension IMGroupTitleChangeItem: IMGroupTitleItemConforming {
    public var item: IMItem {
        self
    }
}
extension IMGroupTitleChangeChatItem: IMGroupTitleItemConforming {
    var item: IMItem {
        self._item()
    }
}

public struct GroupTitleChangeItem: ChatItemOwned, Hashable {
    public static let ingestionClasses: [NSObject.Type] = [
        IMGroupTitleChangeItem.self, IMGroupTitleChangeChatItem.self,
    ]

    public init?(ingesting item: NSObject, context: IngestionContext) {
        switch item {
        case let item as IMGroupTitleChangeItem:
            self.init(item, chatID: context.chatID, service: context.service)
        case let item as IMGroupTitleChangeChatItem:
            self.init(item, chatID: context.chatID, service: context.service)
        default:
            return nil
        }
    }

    init(_ item: IMGroupTitleItemConforming, chatID: String, service: IMServiceStyle) {
        id = item.id
        self.chatID = chatID
        fromMe = item.isFromMe
        time = item.effectiveTime
        title = item.title
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
    public var title: String?
    public var sender: String?

    public var type: ChatItemType {
        .groupTitle
    }
}
