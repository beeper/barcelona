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
    init(_ item: IMDateChatItem, chatGroupID: String?) {
        self.load(item: item, chatGroupID: chatGroupID)
    }
    
    var guid: String?
    var chatGroupID: String?
    var fromMe: Bool?
    var time: Double?
}
