//
//  ErrorChatItem.swift
//  Barcelona
//
//  Created by Eric Rabil on 10/28/21.
//

import Foundation
import IMCore

struct ErrorChatItem: ChatItem, Hashable {
    var type: ChatItemType {
        .error
    }

    static let ingestionClasses: [NSObject.Type] = [IMErrorMessagePartChatItem.self]

    init?(ingesting item: NSObject, context: IngestionContext) {
        self.init(item as! IMErrorMessagePartChatItem, chatID: context.chatID)
    }

    init(_ item: IMErrorMessagePartChatItem, chatID: String) {
        id = item.id
        self.chatID = chatID
        fromMe = item.isFromMe
        time = item.effectiveTime

        if #available(macOS 11.0, *) {
            threadIdentifier = item.threadIdentifier()
            threadOriginator = item.threadOriginatorID
        }
    }

    var id: String
    var chatID: String
    var fromMe: Bool
    var time: Double
    var threadIdentifier: String?
    var threadOriginator: String?
}
