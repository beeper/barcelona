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

struct TextChatItemRepresentation: Content, ChatItemRepresentation {
    init(_ item: IMTextMessagePartChatItem, chatGroupID: String?) {
        text = item.text.string
        
        if let html = item.text.attributedString2Html?.replacingOccurrences(of: "\n", with: "") {
            self.html = html.groups(for: regex)[0][1]
        }
        
        self.load(item: item, chatGroupID: chatGroupID)
    }
    
    var guid: String?
    var chatGroupID: String?
    var fromMe: Bool?
    var time: Double?
    var text: String
    var html: String?
}
