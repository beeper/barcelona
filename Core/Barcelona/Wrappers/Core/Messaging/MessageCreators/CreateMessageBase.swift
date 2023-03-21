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

protocol CreateMessageBase: Codable {
    var threadIdentifier: String? { get set }
    var replyToGUID: String? { get set }
    var replyToPart: Int? { get set }
    var metadata: Message.Metadata? { get set }

    func imMessage(inChat chatIdentifier: String, service: IMServiceStyle) throws -> IMMessage
    func parseToAttributed() -> MessagePartParseResult
    func createIMMessageItem(
        withThreadIdentifier threadIdentifier: String?,
        withChatIdentifier chatIdentifier: String,
        withParseResult parseResult: MessagePartParseResult
    ) throws -> (IMMessageItem, NSMutableAttributedString?)
}

extension CreateMessageBase {
    func resolvedThreadIdentifier(chat: IMChat) -> String? {
        if #available(macOS 10.16, *) {
            if let threadIdentifier = threadIdentifier {
                return threadIdentifier
            } else if let replyToGUID = replyToGUID {
                return IMChatItem.resolveThreadIdentifier(
                    forMessageWithGUID: replyToGUID,
                    part: replyToPart ?? 0,
                    chat: chat
                )
            }
        }
        return nil
    }

    func finalize(
        imMessageItem: IMMessageItem,
        chat: IMChat,
        withSubject subject: NSMutableAttributedString?
    ) throws -> IMMessage {
        if #available(macOS 10.16, *), chat.account.service == .iMessage() {
            imMessageItem.setThreadIdentifier(resolvedThreadIdentifier(chat: chat))
        }

        guard let message = IMMessage.message(fromUnloadedItem: imMessageItem, withSubject: subject) else {
            throw BarcelonaError(code: 500, message: "Failed to construct IMMessage from IMMessageItem")
        }

        if let metadata = metadata {
            message.metadata = metadata
        }

        return message
    }

    public func imMessage(inChat chatIdentifier: String, service: IMServiceStyle) throws -> IMMessage {
        let parseResult = parseToAttributed()

        let (imMessageItem, subject) = try createIMMessageItem(
            withThreadIdentifier: nil,
            withChatIdentifier: chatIdentifier,
            withParseResult: parseResult
        )

        imMessageItem.fileTransferGUIDs = parseResult.transferGUIDs
        guard let chat = IMChat.chat(withIdentifier: chatIdentifier, onService: service, style: nil) else {
            throw CreateMessageError.noIMChatForIdAndService
        }
        imMessageItem.service = chat.account.serviceName
        imMessageItem.accountID = chat.account.uniqueID

        return try finalize(imMessageItem: imMessageItem, chat: chat, withSubject: subject)
    }
}

enum CreateMessageError: Error {
    case noIMChatForIdAndService
}

extension Promise {
    convenience init(_ cb: () throws -> Output) {
        self.init { resolve, reject in
            do {
                try resolve(cb())
            } catch {
                reject(error)
            }
        }
    }
}
