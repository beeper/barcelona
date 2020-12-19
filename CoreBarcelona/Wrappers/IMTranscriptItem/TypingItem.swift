//
//  TypingChatItemRepresentation.swift
//  imessage-rest
//
//  Created by Eric Rabil on 8/12/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

public struct TypingItem: ChatItemRepresentation {
    init(_ item: IMTypingChatItem, chatID: String?) {
        sender = item.sender?.id
        
        self.load(item: item, chatID: chatID)
    }
    
    public var id: String?
    public var chatID: String?
    public var fromMe: Bool?
    public var time: Double?
    public var threadIdentifier: String?
    public var threadOriginator: String?
    public var sender: String?
}
