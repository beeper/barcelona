//
//  AttachmentChatItem.swift
//  imcore-rest
//
//  Created by Eric Rabil on 7/24/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

/// Represents an attachment item
struct AttachmentChatItem: ChatItem, ChatItemAcknowledgable, Hashable {
    static let ingestionClasses: [NSObject.Type] = [IMAttachmentMessagePartChatItem.self]

    init(ingesting item: NSObject, context: IngestionContext) {
        self.init(item as! IMAttachmentMessagePartChatItem, metadata: context.attachment, chatID: context.chatID)
    }

    init(_ item: IMAttachmentMessagePartChatItem, metadata attachmentRepresentation: Attachment? = nil, chatID: String)
    {
        id = item.id
        self.chatID = chatID
        fromMe = item.isFromMe
        time = item.effectiveTime
        transferID = item.transferGUID
        metadata = attachmentRepresentation ?? Attachment(guid: item.transferGUID)
    }

    var id: String
    var chatID: String
    var fromMe: Bool
    var time: Double
    var threadIdentifier: String?
    var threadOriginator: String?
    var transferID: String
    var metadata: Attachment?
    var acknowledgments: [AcknowledgmentChatItem]?

    var type: ChatItemType {
        .attachment
    }
}
