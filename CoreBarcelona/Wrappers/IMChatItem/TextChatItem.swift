//
//  TextChatItem.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/4/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import Vapor

private let regex = try! NSRegularExpression(pattern: "<body.*?>([\\s\\S]*)<\\/body>")

extension TextPart: Content { }

struct TextChatItemRepresentation: Content, ChatItemRepresentation, ChatItemAcknowledgable {
    init(_ item: IMTextMessagePartChatItem, parts: [TextPart], chatGroupID: String?) {
        text = item.text.string
        self.parts = parts
        
        self.load(item: item, chatGroupID: chatGroupID)
    }
    
    var guid: String?
    var chatGroupID: String?
    var fromMe: Bool?
    var time: Double?
    var text: String
    var parts: [TextPart]
    var acknowledgments: [AcknowledgmentChatItemRepresentation]?
}
