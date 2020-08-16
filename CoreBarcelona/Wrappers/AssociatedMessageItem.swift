//
//  AssociatedMessageItem.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/2/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

import Vapor

struct AssociatedMessageItemRepresentation: Content, ChatItemRepresentation {
    init(_ item: IMAssociatedMessageItem, chatGroupID: String?) {
        associatedGUID = item.associatedMessageGUID()
        associatedType = item.associatedMessageType()
        self.load(item: item, chatGroupID: chatGroupID)
    }
    
    var guid: String? = nil
    var chatGroupID: String? = nil
    var fromMe: Bool? = nil
    var time: Double? = nil
    var associatedGUID: String
    var associatedType: Int64
}
