//
//  StatusChatItem.swift
//  imcore-rest
//
//  Created by Eric Rabil on 7/30/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

public enum StatusType: CLongLong, Codable, Hashable {
    case delivered = 1
    case read = 2
    case played = 3
    case kept = 4
    case notDelivered = 7
}

private extension Optional where Wrapped == StatusType {
    var debugString: String {
        guard let value = self else {
            return "(nil)"
        }
        
        return String(describing: value)
    }
}

public struct StatusChatItem: ChatItem, Hashable {
    public static let ingestionClasses: [NSObject.Type] = [IMMessageStatusChatItem.self]
    
    public init(ingesting item: NSObject, context: IngestionContext) {
        self.init(item: item as! IMMessageStatusChatItem, chatID: context.chatID)
    }
    
    public init(item: IMMessageStatusChatItem, chatID: String) {
        id = item.id
        self.chatID = chatID
        fromMe = item.isFromMe
        time = item.effectiveTime
        threadIdentifier = item.threadIdentifier
        threadOriginator = item.threadOriginatorID
        statusType = .init(rawValue: item.statusType)
        itemID = item._item().guid
    }
    
    public var id: String
    public var chatID: String
    public var fromMe: Bool
    public var time: Double
    public var threadIdentifier: String?
    public var threadOriginator: String?
    public var statusType: StatusType?
    public var itemID: String
    
    public var type: ChatItemType {
        .status
    }
    
    public var debugDescription: String {
        "\(type) { id=\(id) fromMe=\(fromMe) status=\(statusType.debugString) }"
    }
}
