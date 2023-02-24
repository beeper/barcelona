//
//  TypingChatItemRepresentation.swift
//  imessage-rest
//
//  Created by Eric Rabil on 8/12/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

struct TypingItem: ChatItemOwned, Hashable {
    static let ingestionClasses: [NSObject.Type] = [IMTypingChatItem.self]

    init(ingesting item: NSObject, context: IngestionContext) {
        self.init(item as! IMTypingChatItem, chatID: context.chatID)
    }

    init(_ item: IMTypingChatItem, chatID: String) {
        id = item.id
        fromMe = item.isFromMe
        sender = item.resolvedSenderID
        time = item.effectiveTime
        self.chatID = chatID
    }

    var id: String = ""
    var chatID: String = ""
    var fromMe: Bool
    var time: Double
    var threadIdentifier: String?
    var threadOriginator: String?
    var sender: String?

    var type: ChatItemType {
        .typing
    }
}
