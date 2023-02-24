//
//  SenderChatItem.swift
//  imcore-rest
//
//  Created by Eric Rabil on 7/24/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

struct SenderItem: ChatItem, Hashable {
    static let ingestionClasses: [NSObject.Type] = [IMSenderChatItem.self]

    init(ingesting item: NSObject, context: IngestionContext) {
        self.init(item as! IMSenderChatItem, chatID: context.chatID)
    }

    init(_ item: IMSenderChatItem, chatID chat: String) {
        id = item.id
        chatID = chat
        fromMe = item.isFromMe
        time = item.effectiveTime
        handleID = item.handle?.id
    }

    var id: String
    var chatID: String
    var fromMe: Bool
    var time: Double
    var threadIdentifier: String?
    var threadOriginator: String?
    var handleID: String?

    var type: ChatItemType {
        .sender
    }
}
