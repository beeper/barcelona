//
//  IMChat+Acknowledgment.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/5/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import IMSharedUtilities
import Logging

enum TapbackError: CustomNSError {
    /// Unknown message.
    case unknownMessage(guid: String)
    /// Unknown subpart.
    case unknownSubpart
    /// Can't create tapback.
    case createTapbackFailed
    /// Couldn't create sender for the tapback.
    case createSenderFailed
    /// Couldn't create `instantMessage` to send in chat.
    case createInstantMessageFailed
    /// Couldn't create the content for the tapback message.
    case createSuperFormatFailed

    var error: String {
        switch self {
        case .unknownMessage(_):
            return "Unknown message"
        case .unknownSubpart:
            return "Unknown subpart"
        case .createTapbackFailed:
            return "Can't create tapback"
        case .createSenderFailed:
            return "Couldn't create sender for the tapback"
        case .createInstantMessageFailed:
            return "Couldn't create instantMessage to send in chat"
        case .createSuperFormatFailed:
            return "Couldn't create the content for the tapback message"
        }
    }

    var errorUserInfo: [String: Any] {
        [NSDebugDescriptionErrorKey: error]
    }
}

extension IMChat {
    /// Sends a tapback for a given message, calling back with a Vapor abort if the operation fails. This must be invoked on the main thread.
    @MainActor public func tapback(
        guid: String,
        itemGUID: String,
        type: Int,
        overridingItemType: UInt8?
    ) throws -> IMMessage {
        guard let message = BLLoadIMMessage(withGUID: guid) else {
            throw TapbackError.unknownMessage(guid: guid)
        }

        let correctGUID: String = {
            if itemGUID == message.id, let subpart = message.subpart(at: 0) {
                return subpart.id
            } else {
                return itemGUID
            }
        }()

        guard let subpart = message.subpart(with: correctGUID) as? IMMessagePartChatItem,
            let summaryInfo = subpart.summaryInfo(for: message, in: self, itemTypeOverride: overridingItemType)
                as? [AnyHashable: Any]
        else {
            throw TapbackError.unknownSubpart
        }

        let rawType = Int64(type)

        if #available(macOS 13, *) {
            return try venturaTapback(
                associatedMessageType: rawType,
                messageSummaryInfo: summaryInfo,
                messagePartChatItem: subpart
            )
        } else {
            return try preVenturaTapback(
                type: rawType,
                subpart: subpart,
                summaryInfo: summaryInfo
            )
        }
    }

    @available(macOS 13.0, *)
    private func venturaTapback(
        associatedMessageType: Int64,
        messageSummaryInfo: [AnyHashable: Any],
        messagePartChatItem: IMMessagePartChatItem
    ) throws -> IMMessage {
        guard let tapback = IMTapback(
            associatedMessageType: associatedMessageType,
            messageSummaryInfo: messageSummaryInfo
        ) else {
            throw TapbackError.createTapbackFailed
        }

        guard let sender = IMTapbackSender(
            tapback: tapback,
            chat: self,
            messagePartChatItem: messagePartChatItem
        ) else {
            throw TapbackError.createSenderFailed
        }

        // This is a simplified implementation of IMTapbackSender's `send` method, but the thing is that we need
        // to return the IMMessage that is being sent, and the `send` method just returns void, so we can't use it

        guard let message = IMMessage.instantMessage(
            withAssociatedMessageContent: sender.attributedContentString(),
            flags: CreateMessage.baseFlags.rawValue,
            associatedMessageGUID: sender.messageGUID(),
            associatedMessageType: associatedMessageType,
            associatedMessageRange: sender.messagePartRange(),
            messageSummaryInfo: sender.messageSummaryInfo(),
            threadIdentifier: sender.threadIdentifier()
        ) else {
            throw TapbackError.createInstantMessageFailed
        }

        send(message)

        return message
    }

    @available(macOS, obsoleted: 13.0, message: "Use venturaTapback instead")
    private func preVenturaTapback(
        type: Int64,
        subpart: IMMessagePartChatItem,
        summaryInfo: [AnyHashable: Any],
        metadata: Message.Metadata? = nil
    ) throws -> IMMessage {
        guard let compatibilityString = CBGeneratePreviewStringForAcknowledgmentType(type, summaryInfo: summaryInfo),
            let superFormat = IMCreateSuperFormatStringFromPlainTextString(compatibilityString)
        else {
            throw TapbackError.createSuperFormatFailed
        }

        let adjustedSummaryInfo = IMChat.__im_adjustMessageSummaryInfo(forSending: summaryInfo)
        let guid = subpart.guid
        let range = subpart.messagePartRange

        var toSendMessage: IMMessage?

        toSendMessage = IMMessage.instantMessage(
            withAssociatedMessageContent: superFormat,
            flags: 0,
            associatedMessageGUID: guid,
            associatedMessageType: type,
            associatedMessageRange: range,
            messageSummaryInfo: adjustedSummaryInfo,
            threadIdentifier: nil
        )

        guard let toSendMessage else {
            throw TapbackError.createInstantMessageFailed
        }

        if let metadata {
            toSendMessage.metadata = metadata
        }

        send(toSendMessage)

        return toSendMessage
    }
}
