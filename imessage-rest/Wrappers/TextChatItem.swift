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

let regex = try! NSRegularExpression(pattern: "<body.*?>([\\s\\S]*)<\\/body>")

struct TextChatItemRepresentation: Content, ChatItemRepresentation {
    init(_ item: IMTextMessagePartChatItem, chatGUID: String?) {
        text = item.text.string
        
        if let html = item.text.attributedString2Html?.replacingOccurrences(of: "\n", with: "") {
            self.html = html.groups(for: regex)[0][1]
        }
        self.load(item: item, chatGUID: chatGUID)
    }
    
    var guid: String?
    var chatGUID: String?
    var fromMe: Bool?
    var time: Double?
    var text: String
    var html: String?
}
