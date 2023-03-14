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

// protocol CreateMessageBase: Codable {
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

    func imMessage(inChat chatIdentifier: String, service: IMServiceStyle) throws -> IMMessage
    func parseToAttributed() -> MessagePartParseResult
    func createIMMessageItem(
        withThreadIdentifier threadIdentifier: String?,
        withChatIdentifier chatIdentifier: String,
        withParseResult parseResult: MessagePartParseResult
    ) throws -> IMMessageItem
}

extension CreateMessageBase {
    @available(macOS 10.16, *)
    func resolvedThreadIdentifier(chat: IMChat) -> String? {
        if let threadIdentifier = threadIdentifier {
            return threadIdentifier
        } else if let replyToGUID = replyToGUID {
            return IMChatItem.resolveThreadIdentifier(
                forMessageWithGUID: replyToGUID,
                part: replyToPart ?? 0,
                chat: chat
            )
        }
        return nil
    }

    public func imMessage(inChat chatIdentifier: String, service: IMServiceStyle) throws -> IMMessage {
        let parseResult = parseToAttributed()

        let imMessageItem = try createIMMessageItem(
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

        if #available(macOS 10.16, *), chat.account.service == .iMessage() {
            imMessageItem.setThreadIdentifier(resolvedThreadIdentifier(chat: chat))
        }

        guard let message = IMMessage.message(fromUnloadedItem: imMessageItem, withSubject: attributedSubject) else {
            throw BarcelonaError(code: 500, message: "Failed to construct IMMessage from IMMessageItem")
        }

        if let metadata = metadata {
            message.metadata = metadata
        }

        return message
    }

    @available(macOS 11.0, *)
    public func newIMMessage(inChat chatId: String, service: IMServiceStyle) throws -> IMMessage {
        guard let chat = IMChat.chat(withIdentifier: chatId, onService: service, style: nil) else {
            throw CreateMessageError.noIMChatForIdAndService
        }

        let message = IMMessage.instantMessage(
            withText: bodyText,
            messageSubject: attributedSubject,
            fileTransferGUIDs: transferGUIDs,
            flags: combinedFlags.rawValue,
            threadIdentifier: resolvedThreadIdentifier(chat: chat)
        )

        guard let myHandle = Registry.sharedInstance.suitableHandle(for: service.rawValue) else {
            throw CreateMessageError.noHandleForSelf
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
    case noIMChatForIdAndService
    case noHandleForSelf
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
