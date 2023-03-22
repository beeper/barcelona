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
    /// The IMChat that we're trying to send in can't retrieve an IMHandle associated with its lastAddressedHandleID
    case noHandleForLastAddressedID

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
        case .noHandleForLastAddressedID:
            return "Couldn't find valid sender IMHandle"
        }
    }

    var errorUserInfo: [String: Any] {
        [NSDebugDescriptionErrorKey: error]
    }
}

extension IMChat {
    public var senderHandle: IMHandle? {
        // We get false positives when sending a message without a sender which correlates to the lastAddressedHandleID
        // of the chat that we're currently in, so use this method to get the correct sender handle
        if let lastAddressedHandleID,
            !lastAddressedHandleID.isEmpty,
            let lastAddressedHandle = account.imHandle(withID: lastAddressedHandleID, alreadyCanonical: false)
        {
            return lastAddressedHandle
        }
        // If there is no lastAddressedHandleID, this is the first message in the chat. In that case, we want to get the
        // handle that corresponds to our default alias, since that just makes sense? That's what we want to send from, by default.
        if let defaultSendingAlias = account.displayName,
            !defaultSendingAlias.isEmpty,
            let defaultHandle = account.imHandle(withID: defaultSendingAlias, alreadyCanonical: false)
        {
            return defaultHandle
        }
        // Otherwise, something is probably off, so log and return the default loginIMHandle
        log.warning(
            "IMChat \(String(describing: self.guid)): lastAddressedHandleID (\(String(describing: lastAddressedHandleID))) and displayName (\(String(describing: account.displayName))) have no associated handles to use for sending"
        )
        return account.loginIMHandle
    }

    /// Sends a tapback for a given message, calling back with a Vapor abort if the operation fails. This must be invoked on the main thread.
    @MainActor public func tapback(
        guid: String,
        itemGUID: String,
        type: Int,
        overridingItemType: UInt8?,
        metadata: Message.Metadata? = nil
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
                overridingItemType: overridingItemType,
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
        guard
            let tapback = IMTapback(
                associatedMessageType: associatedMessageType,
                messageSummaryInfo: messageSummaryInfo
            )
        else {
            throw TapbackError.createTapbackFailed
        }
        guard let sender = IMTapbackSender(tapback: tapback, chat: self, messagePartChatItem: messagePartChatItem)
        else {
            throw TapbackError.createSenderFailed
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
            throw TapbackError.createInstantMessageFailed
        }

        guard let senderHandle else {
            throw TapbackError.noHandleForLastAddressedID
        }
        message.sender = senderHandle

        send(message)

        return message
    }

    @available(macOS, obsoleted: 13.0, message: "Use venturaTapback instead")
    private func preVenturaTapback(
        type: Int64,
        overridingItemType: UInt8?,
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

        guard let senderHandle else {
            throw TapbackError.noHandleForLastAddressedID
        }
        toSendMessage.sender = senderHandle

        send(toSendMessage)

        return toSendMessage
    }
}
