//
//  CreateMessageBase.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 2/17/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import IMSharedUtilities
import Logging

protocol CreateMessageBase {
    var threadIdentifier: String? { get }
    var replyToGUID: String? { get }
    var replyToPart: Int? { get }
    var metadata: Message.Metadata? { get }
    var combinedFlags: IMMessageFlags { get }
    var attributedSubject: NSMutableAttributedString? { get }
    var balloonBundleID: String? { get }
    var payloadData: Data? { get }
    var bodyText: NSAttributedString { get }
    var transferGUIDs: [String] { get }

    func imMessage(inChat chat: IMChat) throws -> IMMessage
}

extension CreateMessageBase {
    public func imMessage(inChat chat: IMChat) throws -> IMMessage {
        let message = IMMessage.instantMessage(
            withText: bodyText,
            messageSubject: attributedSubject,
            fileTransferGUIDs: transferGUIDs,
            flags: combinedFlags.rawValue,
            threadIdentifier: threadIdentifier ?? replyToGUID.flatMap {
                IMChatItem.resolveThreadIdentifier(forMessageWithGUID: $0, part: replyToPart ?? 0, chat: chat)
            }
        )

        guard let myHandle = chat.senderHandle else {
            throw CreateMessageError.noHandleForLastAddressedID
        }

        message.sender = myHandle

        if let metadata {
            message.metadata = metadata
        }

        if let balloonBundleID {
            message.balloonBundleID = balloonBundleID
        }

        if let payloadData {
            message.payloadData = payloadData
        }

        return message
    }
}

enum CreateMessageError: Error {
    case noHandleForLastAddressedID
}
