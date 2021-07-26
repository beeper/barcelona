//
//  IncomingMessageCommand.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 5/24/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import Barcelona

private extension Message {
    var blSenderGUID: String {
        "\(service.rawValue);\(isGroup ? "+" : "-");\(sender!)"
    }
    
    var isGroup: Bool {
        IMChat.resolve(withIdentifier: chatID!)!.isGroup
    }
    
    var textContent: String {
        let items: [TextChatItem] = items.compactMap {
            guard case let .text(item) = $0 else {
                return nil
            }
            
            return item
        }
        
        return items.reduce(into: "") { acc, item in
            acc += item.text
        }
    }
}

public struct BLMessage: Codable, ChatResolvable {
    public var guid: String
    public var timestamp: Double
    public var subject: String?
    public var text: String
    public var chat_guid: String
    public var sender_guid: String
    public var is_from_me: Bool
    public var thread_originator_guid: String?
    public var thread_originator_part: Int
    public var attachments: [BLAttachment]?
    public var associated_message: BLAssociatedMessage?
    public var group_action_type: Int?
    public var new_group_title: String?
    
    public init(message: Message) {
        guid = message.id
        timestamp = (message.time ?? 0) / 1000
        subject = message.subject
        text = message.textContent
        chat_guid = IMChat.resolve(withIdentifier: message.chatID!)!.guid!
        sender_guid = message.blSenderGUID
        is_from_me = message.fromMe ?? false
        thread_originator_guid = message.threadIdentifier
        thread_originator_part = 0
        attachments = message.fileTransferIDs.compactMap {
            BLAttachment(guid: $0)
        }
        
        for item in message.items {
            switch item {
            case .groupTitle(let changeItem):
                self.new_group_title = changeItem.title
            case .groupAction(let action):
                self.group_action_type = Int(action.actionType)
            default:
                break
            }
        }
    }
    
    public static func < (left: BLMessage, right: BLMessage) -> Bool {
        left.timestamp < right.timestamp
    }
    
    public static func > (left: BLMessage, right: BLMessage) -> Bool {
        left.timestamp < right.timestamp
    }
    
    public static func <= (left: BLMessage, right: BLMessage) -> Bool {
        left.timestamp <= right.timestamp
    }
    
    public static func >= (left: BLMessage, right: BLMessage) -> Bool {
        left.timestamp >= right.timestamp
    }
}
