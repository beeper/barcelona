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
struct AttachmentChatItem: ChatItemRepresentation, ChatItemAcknowledgable {
    init(_ item: IMAttachmentMessagePartChatItem, metadata attachmentRepresentation: Attachment?, chatID: String?) {
        transferID = item.transferGUID
        metadata = attachmentRepresentation
        self.load(item: item, chatID: chatID)
    }
    
    /// Attempts to fulfill the attachment data using existing sources from IMFileTransferCenter
    init(_ item: IMAttachmentMessagePartChatItem, chatID: String?) {
        self.init(item, metadata: Attachment(guid: item.transferGUID), chatID: chatID)
    }
    
    var id: String?
    var chatID: String?
    var fromMe: Bool?
    var time: Double?
    var transferID: String
    var metadata: Attachment?
    var acknowledgments: [AcknowledgmentChatItem]?
}
