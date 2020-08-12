//
//  ChatItem.swift
//  imcore-rest
//
//  Created by Eric Rabil on 7/24/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import Vapor

struct DateTranscriptChatItemRepresentation: Content, ChatItemRepresentation {
    init(_ item: IMDateChatItem, chatGUID: String?) {
        self.load(item: item, chatGUID: chatGUID)
    }
    
    var guid: String?
    var chatGUID: String?
    var fromMe: Bool?
    var time: Double?
}
