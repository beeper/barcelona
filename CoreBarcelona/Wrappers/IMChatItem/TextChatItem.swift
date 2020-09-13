//
//  TextChatItem.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/4/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

private let regex = try! NSRegularExpression(pattern: "<body.*?>([\\s\\S]*)<\\/body>")

struct TextChatItem: ChatItemRepresentation, ChatItemAcknowledgable {
    init(_ item: IMTextMessagePartChatItem, parts: [TextPart], chatID: String?) {
        self.parts = parts
        
        self.load(item: item, chatID: chatID)
    }
    
    var id: String?
    var chatID: String?
    var fromMe: Bool?
    var time: Double?
    var parts: [TextPart]
    var acknowledgments: [AcknowledgmentChatItem]?
}
