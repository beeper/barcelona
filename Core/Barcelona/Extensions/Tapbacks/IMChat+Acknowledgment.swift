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

private let chatItemGUIDExtractor = try! NSRegularExpression(pattern: "(?:\\w+:\\d+)\\/([\\w-]+)")

extension IMChat {
    /**
     Sends a tapback for a given message, calling back with a Vapor abort if the operation fails. This must be invoked on the main thread.
     */
    @MainActor
    public func tapback(
        guid: String,
        itemGUID: String,
        type: Int,
        overridingItemType: UInt8?,
        metadata: Message.Metadata? = nil
    ) throws -> IMMessage {
        guard let message = BLLoadIMMessage(withGUID: guid) else {
            throw BarcelonaError(code: 404, message: "Unknown message: \(guid)")
        }

        guard Thread.isMainThread else {
            preconditionFailure("IMChat.tapback() must be invoked on the main thread")
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
            throw BarcelonaError(code: 404, message: "Unknown subpart")
        }

        let rawType = Int64(type)

        if #available(macOS 13, iOS 16.0, *) {
            return try venturaTapback(
                associatedMessageType: rawType,
                messageSummaryInfo: summaryInfo,
                messagePartChatItem: subpart
            )
        } else {
            return try preVenturaTapback(
                type: rawType,
                overridingItemType: overridingItemType,
                subpart: subpart,
                summaryInfo: summaryInfo
            )
        }
    }

    @available(macOS 13.0, *)
    @available(iOS 13.0, *)
    public func venturaTapback(
        associatedMessageType: Int64,
        messageSummaryInfo: [AnyHashable: Any],
        messagePartChatItem: IMMessagePartChatItem
    ) throws -> IMMessage {
        guard
            let tapback = IMTapback(
                associatedMessageType: associatedMessageType,
                messageSummaryInfo: messageSummaryInfo
            )
        else {
            throw BarcelonaError(code: 500, message: "Can't create tapback")
        }
        guard let sender = IMTapbackSender(tapback: tapback, chat: self, messagePartChatItem: messagePartChatItem)
        else {
            throw BarcelonaError(code: 500, message: "Couldn't create sender for the tapback")
        }

        // This is a simplified implementation of IMTapbackSender's `send` method, but the thing is that we need
        // to return the IMMessage that is being sent, and the `send` method just returns void, so we can't use it

        guard
            let message = IMMessage.instantMessage(
                withAssociatedMessageContent: sender.attributedContentString(),
                flags: 0,
                associatedMessageGUID: sender.messageGUID(),
                associatedMessageType: associatedMessageType,
                associatedMessageRange: sender.messagePartRange(),
                messageSummaryInfo: sender.messageSummaryInfo(),
                threadIdentifier: sender.threadIdentifier()
            )
        else {
            throw BarcelonaError(code: 500, message: "Couldn't create instantMessage to send in chat")
        }

        send(message)

        return message
    }

    @available(macOS, obsoleted: 13.0, message: "Use venturaTapback instead")
    @available(iOS, obsoleted: 16.0, message: "Use venturaTapback instead")
    public func preVenturaTapback(
        type: Int64,
        overridingItemType: UInt8?,
        subpart: IMMessagePartChatItem,
        summaryInfo: [AnyHashable: Any],
        metadata: Message.Metadata? = nil
    ) throws -> IMMessage {
        guard let compatibilityString = CBGeneratePreviewStringForAcknowledgmentType(type, summaryInfo: summaryInfo),
            let superFormat = IMCreateSuperFormatStringFromPlainTextString(compatibilityString)
        else {
            throw BarcelonaError(code: 500, message: "Internal server error")
        }

        let adjustedSummaryInfo = IMChat.__im_adjustMessageSummaryInfo(forSending: summaryInfo)
        let guid = subpart.guid
        let range = subpart.messagePartRange

        var toSendMessage: IMMessage?

        if #available(iOS 14, macOS 10.16, watchOS 7, *) {
            toSendMessage = IMMessage.instantMessage(
                withAssociatedMessageContent: superFormat,
                flags: 0,
                associatedMessageGUID: guid,
                associatedMessageType: type,
                associatedMessageRange: range,
                messageSummaryInfo: adjustedSummaryInfo,
                threadIdentifier: nil
            )
        } else {
            toSendMessage = IMMessage.instantMessage(
                withAssociatedMessageContent: superFormat,
                flags: 0,
                associatedMessageGUID: guid,
                associatedMessageType: type,
                associatedMessageRange: range,
                messageSummaryInfo: adjustedSummaryInfo
            )
        }

        guard let toSendMessage else {
            throw BarcelonaError(code: 500, message: "Couldn't create tapback message")
        }

        if let metadata {
            toSendMessage.metadata = metadata
        }

        send(toSendMessage)

        return toSendMessage
    }
}
