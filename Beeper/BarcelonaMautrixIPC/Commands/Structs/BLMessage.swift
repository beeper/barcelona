//
//  IncomingMessageCommand.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 5/24/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Barcelona
import Foundation
import IMCore
import Logging

private let log = Logger(label: "BLMessage")

extension Message {
    fileprivate var blSenderGUID: String? {
        guard let sender = sender, !fromMe else {
            return nil
        }

        return BLCreateGUID(service, isGroup == true ? .group : .instantMessage, sender)
    }

    fileprivate var groupID: String? {
        imChat?.groupID
    }

    fileprivate var isGroup: Bool? {
        imChat?.isGroup
    }

    fileprivate var textContent: String {
        items.map(\.item)
            .reduce(into: [String]()) { text, item in
                switch item {
                case let item as TextChatItem:
                    text.append(item.text)
                case let item as PluginChatItem:
                    if let fallbackText = item.fallback?.text {
                        text.append(fallbackText)
                    }
                default:
                    break
                }
            }
            .joined(separator: " ")
    }
}

extension ParticipantChangeItem {
    fileprivate func blTargetGUID(on service: IMServiceStyle, isGroup: Bool) -> String? {
        guard let targetID else {
            log.warning("targetID is nil for change item \(id); can't create target GUID")
            return nil
        }

        return BLCreateGUID(service, isGroup ? .group : .instantMessage, targetID)
    }
}

public struct BLMessage: Codable, ChatResolvable {
    public var guid: String
    public var timestamp: Double
    public var subject: String?
    public var text: String
    public var chat_guid: String
    public var thread_id: String?
    public var sender_guid: String?
    public var service: String
    public var is_from_me: Bool
    public var thread_originator_guid: String?
    public var thread_originator_part: Int
    public var attachments: [BLAttachment]?
    var associated_message: BLAssociatedMessage?
    public var group_action_type: Int?
    public var new_group_title: String?
    public var is_audio_message: Bool?
    public var is_read: Bool
    public var item_type: Int64?
    public var target_guid: String?
    public var rich_link: RichLinkMetadata?
    public var metadata: Message.Metadata?

    public init(message: Message) {
        guid = message.id
        timestamp = message.time / 1000  // mautrix-imessage expects this to be seconds
        subject = message.subject
        text = message.textContent

        if message.imChat == nil {
            log.warning("Creating BLMessage from Message with a nil imChat \(message.debugDescription)")
        }

        chat_guid = message.chatGUID
        thread_id = message.groupID
        sender_guid = message.blSenderGUID
        service = message.service.rawValue
        is_from_me = message.fromMe
        thread_originator_guid = message.threadOriginator
        thread_originator_part = 0
        attachments = message.fileTransferIDs.compactMap {
            BLAttachment(guid: $0)
        }
        is_audio_message = message.isAudioMessage
        is_read = message.isReadByMe
        metadata = message.metadata

        for item in message.items {
            switch item.item {
            case let changeItem as GroupTitleChangeItem:
                self.new_group_title = changeItem.title
                self.item_type = IMItemType.groupTitleChange.rawValue
            case let action as ParticipantChangeItem:
                self.group_action_type = Int(action.changeType)
                self.item_type = IMItemType.participantChange.rawValue
                self.target_guid = action.blTargetGUID(on: message.service, isGroup: message.imChat?.isGroup == true)
            case let item as GroupActionItem:
                self.group_action_type = Int(item.actionType.rawValue)
                self.item_type = IMItemType.groupAction.rawValue
            case let acknowledgment as AcknowledgmentChatItem:
                guard let parsedID = CBMessageItemIdentifierData(rawValue: acknowledgment.associatedID) else {
                    log.error("Failed to parse associatedID \(acknowledgment.associatedID)", source: "BLMessage")
                    continue
                }

                self.associated_message = BLTapback(
                    chat_guid: chat_guid,
                    target_guid: acknowledgment.associatedID,
                    target_part: parsedID.part ?? 0,
                    type: Int(acknowledgment.acknowledgmentType)
                )
            case let plugin as PluginChatItem:
                attachments = message.fileTransferIDs
                    .filter { id in
                        !plugin.attachments.map(\.id).contains(id)
                    }
                    .compactMap {
                        BLAttachment(guid: $0)
                    }
                if let richLink = plugin.richLink {
                    rich_link = richLink
                } else if let extensionData = plugin.extension {
                    rich_link = RichLinkMetadata(
                        extensionData: extensionData,
                        attachments: plugin.attachments,
                        fallbackText: &text
                    )
                }
                if rich_link?.usableForMatrix == false {
                    rich_link = nil
                }
            default:
                continue
            }
        }
    }

    public static func < (left: BLMessage, right: BLMessage) -> Bool {
        left.timestamp < right.timestamp
    }
}
