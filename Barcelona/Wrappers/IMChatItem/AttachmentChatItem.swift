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
public struct AttachmentChatItem: ChatItem, ChatItemAcknowledgable, Hashable {
    public static let ingestionClasses: [NSObject.Type] = [IMAttachmentMessagePartChatItem.self]
    
    public init(ingesting item: NSObject, context: IngestionContext) {
        self.init(item as! IMAttachmentMessagePartChatItem, metadata: context.attachment, chatID: context.chatID)
    }
    
    init(_ item: IMAttachmentMessagePartChatItem, metadata attachmentRepresentation: Attachment? = nil, chatID: String) {
        id = item.id
        self.chatID = chatID
        fromMe = item.isFromMe
        time = item.effectiveTime
        transferID = item.transferGUID
        metadata = attachmentRepresentation ?? Attachment(guid: item.transferGUID)
    }
    
    public var id: String
    public var chatID: String
    public var fromMe: Bool
    public var time: Double
    public var threadIdentifier: String?
    public var threadOriginator: String?
    public var transferID: String
    public var metadata: Attachment?
    public var acknowledgments: [AcknowledgmentChatItem]?
    
    public var type: ChatItemType {
        .attachment
    }
}
