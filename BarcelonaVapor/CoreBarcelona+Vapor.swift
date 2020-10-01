//
//  CoreBarcelona+Vapor.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/3/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import CoreBarcelona
import Vapor

// MARK: - Error System
extension BarcelonaError: AbortError {
    public var status: HTTPResponseStatus {
        .init(statusCode: self.code, reasonPhrase: self.message)
    }
}

// MARK: - Chat Objects
extension Chat: Content { }
extension ChatUnreadCountRepresentation: Content { }
extension BulkChatRepresentation: Content { }
extension ChatIDRepresentation: Content { }
extension MessagePart: Content { }
extension ChatConfigurationRepresentation: Content { }
extension CreateMessage: Content { }
extension BulkAttachmentRepresentation: Content { }

// MARK: - Message Objects
extension Message: Content { }
extension BulkMessageRepresentation: Content { }
extension BulkMessageIDRepresentation: Content { }
extension DeleteMessage: Content { }
extension DeleteMessageRequest: Content { }

// MARK: - ChatItem
extension ChatItem: Content { }
extension BulkChatItemRepresentation: Content { }

// MARK: - Handle Objects
extension BulkHandleRepresentation: Content { }
extension BulkHandleIDRepresentation: Content { }
extension Handle: Content { }

// MARK: - Contact Objects
extension Contact: Content { }
extension ContactIDRepresentation: Content { }
extension BulkContactRepresentation: Content { }

// MARK: - Core Objects
extension Attachment: Content { }
extension TextPart: Content { }
extension StickerInformation: Content { }

// MARK: - Message Items
extension AssociatedMessageItem: Content { }
extension SenderItem: Content { }
extension DateItem: Content { }
extension GroupTitleChangeItem: Content { }
extension ParticipantChangeItem: Content { }
extension GroupActionItem: Content { }
extension TypingItem: Content { }
extension AttachmentChatItem: Content { }
extension TextChatItem: Content { }
extension StatusChatItem: Content { }
extension PluginChatItem: Content { }
extension AcknowledgmentChatItem: Content { }
extension StickerChatItem: Content { }
extension ActionChatItem: Content { }
