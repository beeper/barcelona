//
//  MessageSending.swift
//  Barcelona
//
//  Created by Eric Rabil on 11/2/21.
//

import BarcelonaDB
import Combine
import Foundation
import IMCore
import IMDPersistence
import Logging

extension IMChat {
    static var regressionTesting_disableServiceRefresh = false
}

extension IMChat {
    var log: Logging.Logger {
        Logger(label: "IMChat")
    }
    /// Stored instance variable on IMChat
    private var hasRefreshedServiceForSending: Bool {
        get { value(forKey: "_hasRefreshedServiceForSending") as! Bool }
        set { setValue(false, forKey: "_hasRefreshedServiceForSending") }
    }

    /// Refreshes the chat service for sending, runs once per chat.
    func refreshServiceForSendingIfNeeded() {
        guard !IMChat.regressionTesting_disableServiceRefresh else {
            return
        }
        if let lastMessageItem = lastFinishedMessageItem,
            lastMessageItem.isFinished,  // message must be finished
            lastMessageItem.errorCode == .noError,  // message must have no error
            let serviceStyle = lastMessageItem.serviceStyle,
            serviceStyle == .iMessage,  // last item must have been sent on iMessage
            let messageAccount = serviceStyle.account,
            self.account != messageAccount
        {  // The self.account must not be equal to the iMessage account
            // We are targeted to iMessage, but we don't really know why. Let's retarget to iMessage and see what IDS thinks.
            log.info(
                "Previous message on service \(serviceStyle.rawValue) appears to have been successful, but my service is \(String(describing: self.account.serviceName)). I'm going to try my best to refresh the ID query.",
                source: "ERChat"
            )
            _setAccount(messageAccount, locally: true)
        } else if !forceRefresh && hasRefreshedServiceForSending {
            if let lastMessageItem = lastMessage?._imMessageItem, lastMessageItem.serviceStyle == account.service?.id {
                if !lastMessageItem.isFromMe() {
                    return
                }
                switch lastMessageItem.errorCode {
                case .remoteUserDoesNotExist, .remoteUserInvalid, .remoteUserRejected, .remoteUserIncompatible:
                    break
                default:
                    return
                }
            }
        }
        hasRefreshedServiceForSending = false
        refreshServiceForSending()
        let id = self.chatIdentifier
        let serviceName = account.serviceName ?? "nil"
        log.info("The resolved service for \(String(describing: id)) is currently \(serviceName)", source: "ERChat")
    }
}

extension Chat {
    private func markAsRead() {
        if ProcessInfo.processInfo.environment.keys.contains("BARCELONA_GHOST_REPLIES") {
            return
        }
        imChat.markAllMessagesAsRead()
    }

    public func sendReturningRaw(message createMessage: CreateMessage) async throws -> IMMessage {
        return try await imChat.send(message: createMessage)
    }

    public func send(message createMessage: CreateMessage) async throws -> Message {
        guard let service else {
            throw BarcelonaError(code: 500, message: "No service for \(id)")
        }

        return Message(
            messageItem: try await sendReturningRaw(message: createMessage)._imMessageItem,
            chatID: imChat.chatIdentifier,
            service: service
        )
    }

    public func tapback(_ creation: TapbackCreation) async throws -> Message {
        markAsRead()
        guard let service else {
            throw BarcelonaError(code: 500, message: "No service for \(id)")
        }

        let message = try await imChat.tapback(
            guid: creation.message,
            itemGUID: creation.item,
            type: creation.type,
            overridingItemType: nil
        )

        return Message(messageItem: message._imMessageItem, chatID: imChat.chatIdentifier, service: service)
    }
}
