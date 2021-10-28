//
//  IncomingMessageCommand.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 5/24/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import Barcelona
import IMCore

private extension Message {
    var blSenderGUID: String? {
        guard let sender = sender, !fromMe else {
            return nil
        }
        
        return "\(service.rawValue);\(isGroup ? "+" : "-");\(sender)"
    }
    
    var isGroup: Bool {
        IMChat.resolve(withIdentifier: chatID)!.isGroup
    }
    
    var textContent: String {
        items.map(\.item).reduce(into: [String]()) { text, item in
            switch item {
            case let item as TextChatItem:
                text.append(item.text)
            case let item as PluginChatItem:
                if let fallbackText = item.fallback?.text {
                    text.append(fallbackText)
                }
            case let item as PhantomChatItem:
                text.append("`Unknown item \(item.className)`")
            default:
                break
            }
        }.joined(separator: " ")
    }
}

public struct BLMessage: Codable, ChatResolvable {
    public var guid: String
    public var timestamp: Double
    public var subject: String?
    public var text: String
    public var chat_guid: String
    public var sender_guid: String?
    public var is_from_me: Bool
    public var thread_originator_guid: String?
    public var thread_originator_part: Int
    public var attachments: [BLAttachment]?
    public var associated_message: BLAssociatedMessage?
    public var group_action_type: Int?
    public var new_group_title: String?
    
    public init(message: Message) {
        guid = message.id
        timestamp = message.time
        subject = message.subject
        text = message.textContent
        chat_guid = IMChat.resolve(withIdentifier: message.chatID)!.guid!
        sender_guid = message.blSenderGUID
        is_from_me = message.fromMe
        thread_originator_guid = message.threadOriginator
        thread_originator_part = 0
        attachments = message.fileTransferIDs.compactMap {
            BLAttachment(guid: $0)
        }
        
        for item in message.items {
            switch item.item {
            case let changeItem as GroupTitleChangeItem:
                self.new_group_title = changeItem.title
            case let action as GroupActionItem:
                self.group_action_type = Int(action.actionType.rawValue)
            case let acknowledgment as AcknowledgmentChatItem:
                guard let parsedID = CBMessageItemIdentifierData(rawValue: acknowledgment.associatedID), let part = parsedID.part else {
                    continue
                }
                
                self.associated_message = BLTapback(chat_guid: chat_guid, target_guid: acknowledgment.associatedID, target_part: part, type: Int(acknowledgment.acknowledgmentType))
            case let plugin as PluginChatItem:
                attachments = message.fileTransferIDs.filter { id in
                    !plugin.attachments.map(\.id).contains(id)
                }.compactMap {
                    BLAttachment(guid: $0)
                }
            default:
                continue
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
