//
//  AssociatedMessageItem.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/2/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

struct AssociatedMessageItem: ChatItemRepresentation {
    init(_ item: IMAssociatedMessageItem, chatID: String?) {
        associatedID = item.associatedMessageGUID()
        associatedType = item.associatedMessageType()
        self.load(item: item, chatID: chatID)
    }
    
    var id: String? = nil
    var chatID: String? = nil
    var fromMe: Bool? = nil
    var time: Double? = nil
    var associatedID: String
    var associatedType: Int64
}
