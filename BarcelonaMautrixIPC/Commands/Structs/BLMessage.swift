//
//  IncomingMessageCommand.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 5/24/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import CoreBarcelona

private extension Message {
    var blSenderGUID: String {
        "\(service.rawValue);\(isGroup ? "+" : "-");\(sender!)"
    }
    
    var isGroup: Bool {
        IMChat.resolve(withIdentifier: chatID!)!.isGroup
    }
}

public struct BLMessage: Codable, ChatResolvable {
    public var guid: String
    public var timestamp: Double?
    public var subject: String?
    public var text: String
    public var chat_guid: String
    public var sender_guid: String
    public var is_from_me: Bool
    public var thread_originator_guid: String?
    public var thread_originator_part: Int
    public var attachments: [BLAttachment]?
    public var associated_message: BLAssociatedMessage?
    
    public init(message: Message) {
        guid = message.id
        timestamp = message.time!
        subject = message.subject
        text = message.description!
        chat_guid = IMChat.resolve(withIdentifier: message.chatID!)!.guid!
        sender_guid = message.blSenderGUID
        is_from_me = message.fromMe ?? false
        thread_originator_guid = message.threadIdentifier
        thread_originator_part = 0
        attachments = message.fileTransferIDs.compactMap {
            BLAttachment(guid: $0)
        }
    }
}
