//
//  AssociatedMessageItem.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/2/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation

import Vapor

struct AssociatedMessageItemRepresentation: Content, ChatItemRepresentation {
    init(_ item: IMAssociatedMessageItem, chatGUID: String?) {
        associatedGUID = item.associatedMessageGUID()
        associatedType = item.associatedMessageType()
        self.load(item: item, chatGUID: chatGUID)
    }
    
    var guid: String? = nil
    var chatGUID: String? = nil
    var fromMe: Bool? = nil
    var time: Double? = nil
    var associatedGUID: String
    var associatedType: Int64
}
