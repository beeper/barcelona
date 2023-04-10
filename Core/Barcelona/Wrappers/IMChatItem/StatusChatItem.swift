//
//  StatusChatItem.swift
//  imcore-rest
//
//  Created by Eric Rabil on 7/30/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

enum StatusType: CLongLong, Codable, Hashable {
    case delivered = 1
    case read = 2
    case played = 3
    case kept = 4
    case notDelivered = 7
}

extension Optional where Wrapped == StatusType {
    fileprivate var debugString: String {
        guard let value = self else {
            return "(nil)"
        }

        return String(describing: value)
    }
}

struct StatusChatItem: ChatItemOwned, Hashable {
    static let ingestionClasses: [NSObject.Type] = [IMMessageStatusChatItem.self]

    init(ingesting item: NSObject, context: IngestionContext) {
        self.init(item: item as! IMMessageStatusChatItem, chatID: context.chatID)
    }

    init(item: IMMessageStatusChatItem, chatID: String) {
        id = item.id
        self.chatID = chatID
        fromMe = !item.isFromMe
        time = item.effectiveTime
        threadIdentifier = item.threadIdentifier
        threadOriginator = item.threadOriginatorID
        statusType = .init(rawValue: item.statusType)
        itemID = item._item().guid
        sender = item._item().handle
    }

    var id: String
    var chatID: String
    var fromMe: Bool
    var time: Double
    var sender: String?
    var threadIdentifier: String?
    var threadOriginator: String?
    var statusType: StatusType?
    var itemID: String

    var type: ChatItemType {
        .status
    }

    var debugDescription: String {
        "\(type) { id=\(id) fromMe=\(fromMe) status=\(statusType.debugString) }"
    }
}
