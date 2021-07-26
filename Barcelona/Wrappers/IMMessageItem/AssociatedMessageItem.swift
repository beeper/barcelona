//
//  AssociatedMessageItem.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/2/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

public struct AssociatedMessageItem: ChatItem, Hashable {
    public static let ingestionClasses: [NSObject.Type] = [IMAssociatedMessageItem.self]
    
    public init(ingesting item: NSObject, context: IngestionContext) {
        self.init(item as! IMAssociatedMessageItem, chatID: context.chatID)
    }
    
    init(_ item: IMAssociatedMessageItem, chatID: String?) {
        associatedID = item.associatedMessageGUID()
        associatedType = item.associatedMessageType()
        self.load(item: item, chatID: chatID)
    }
    
    public var id: String?
    public var chatID: String?
    public var fromMe: Bool?
    public var time: Double?
    public var threadIdentifier: String?
    public var threadOriginator: String?
    public var associatedID: String
    public var associatedType: Int64
    
    public var type: ChatItemType {
        .associated
    }
}
