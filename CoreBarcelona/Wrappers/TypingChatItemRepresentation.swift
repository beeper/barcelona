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
    init(_ item: IMTypingChatItem, chatGUID: String?) {
        sender = item.sender?.id
        
        self.load(item: item, chatGUID: chatGUID)
    }
    
    var guid: String?
    var chatGUID: String?
    var fromMe: Bool?
    var time: Double?
    var sender: String?
}
