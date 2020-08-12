//
//  SenderChatItem.swift
//  imcore-rest
//
//  Created by Eric Rabil on 7/24/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import Vapor


struct SenderTranscriptChatItemRepresentation: Content, ChatItemRepresentation {
    init(_ item: IMSenderChatItem, chatGUID chat: String?) {
        handleID = item.handle.id
        self.load(item: item, chatGUID: chat)
    }
    
    var guid: String?
    var chatGUID: String?
    var fromMe: Bool?
    var time: Double?
    var handleID: String
}
