//
//  ChatItem.swift
//  imcore-rest
//
//  Created by Eric Rabil on 7/24/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

struct DateItem: ChatItem, Hashable {
    static let ingestionClasses: [NSObject.Type] = [IMDateChatItem.self]

    init(ingesting item: NSObject, context: IngestionContext) {
        self.init(item as! IMDateChatItem, chatID: context.chatID)
    }

    init(_ item: IMDateChatItem, chatID: String) {
        id = item.id
        self.chatID = chatID
        fromMe = item.isFromMe
        time = item.effectiveTime
        threadIdentifier = item.threadIdentifier
        threadOriginator = item.threadOriginatorID
    }

    var id: String
    var chatID: String
    var fromMe: Bool
    var time: Double
    var threadIdentifier: String?
    var threadOriginator: String?

    var type: ChatItemType {
        .date
    }
}
