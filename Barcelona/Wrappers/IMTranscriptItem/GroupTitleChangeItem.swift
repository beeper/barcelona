//
//  GroupTitleChangedItem.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/9/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

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
    
    init(_ item: IMGroupTitleChangeItem, chatID: String?) {
        title = item.title
        sender = item.sender
        
        self.load(item: item, chatID: chatID)
    }
    
    init(_ item: IMGroupTitleChangeChatItem, chatID: String?) {
        title = item.title
        sender = (item.handle ?? item.sender)?.id
        
        self.load(item: item, chatID: chatID)
    }
    
    public var id: String?
    public var chatID: String?
    public var fromMe: Bool?
    public var time: Double?
    public var threadIdentifier: String?
    public var threadOriginator: String?
    public var title: String?
    public var sender: String?
    
    public var type: ChatItemType {
        .groupTitle
    }
}
