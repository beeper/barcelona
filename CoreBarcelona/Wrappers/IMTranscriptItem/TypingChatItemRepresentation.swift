//
//  TypingChatItemRepresentation.swift
//  imessage-rest
//
//  Created by Eric Rabil on 8/12/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import Vapor

struct TypingChatItemRepresentation: Content, ChatItemRepresentation {
    init(_ item: IMTypingChatItem, chatGroupID: String?) {
        sender = item.sender?.id
        
        self.load(item: item, chatGroupID: chatGroupID)
    }
    
    var guid: String?
    var chatGroupID: String?
    var fromMe: Bool?
    var time: Double?
    var sender: String?
}
