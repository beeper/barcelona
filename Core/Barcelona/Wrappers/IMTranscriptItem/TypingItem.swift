//
//  TypingChatItemRepresentation.swift
//  imessage-rest
//
//  Created by Eric Rabil on 8/12/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

public struct TypingItem: ChatItemOwned, Hashable {
    public static let ingestionClasses: [NSObject.Type] = [IMTypingChatItem.self]

    public init(ingesting item: NSObject, context: IngestionContext) {
        self.init(item as! IMTypingChatItem, chatID: context.chatID)
    }

    init(_ item: IMTypingChatItem, chatID: String) {
        id = item.id
        fromMe = item.isFromMe
        sender = item.resolvedSenderID
        time = item.effectiveTime
        self.chatID = chatID
    }

    public var id: String = ""
    public var chatID: String = ""
    public var fromMe: Bool
    public var time: Double
    public var threadIdentifier: String?
    public var threadOriginator: String?
    public var sender: String?

    public var type: ChatItemType {
        .typing
    }
}
