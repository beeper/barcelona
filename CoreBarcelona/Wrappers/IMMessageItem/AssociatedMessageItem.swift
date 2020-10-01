//
//  AssociatedMessageItem.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/2/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

public struct AssociatedMessageItem: ChatItemRepresentation {
    init(_ item: IMAssociatedMessageItem, chatID: String?) {
        associatedID = item.associatedMessageGUID()
        associatedType = item.associatedMessageType()
        self.load(item: item, chatID: chatID)
    }
    
    public var id: String? = nil
    public var chatID: String? = nil
    public var fromMe: Bool? = nil
    public var time: Double? = nil
    public var associatedID: String
    public var associatedType: Int64
}
