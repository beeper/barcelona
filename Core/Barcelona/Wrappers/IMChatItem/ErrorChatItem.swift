//
//  ErrorChatItem.swift
//  Barcelona
//
//  Created by Eric Rabil on 10/28/21.
//

import Foundation
import IMCore

public struct ErrorChatItem: ChatItem, Hashable {
    public var type: ChatItemType {
        .error
    }

    public static let ingestionClasses: [NSObject.Type] = [IMErrorMessagePartChatItem.self]

    public init?(ingesting item: NSObject, context: IngestionContext) {
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

    public var id: String
    public var chatID: String
    public var fromMe: Bool
    public var time: Double
    public var threadIdentifier: String?
    public var threadOriginator: String?
}
