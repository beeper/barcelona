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

extension Date {
    static func now() -> Date { Date() }
}

extension IMChat {
    static var regressionTesting_disableServiceRefresh = false
}

extension Encodable {
    var prettyJSON: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        return try! String(decoding: encoder.encode(encode(to:)), as: UTF8.self)
    }
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
        log.info("The resolved service for \(id) is currently \(serviceName)", source: "ERChat")
    }
}

extension Chat {
    private func markAsRead() {
        if ProcessInfo.processInfo.environment.keys.contains("BARCELONA_GHOST_REPLIES") {
            return
        }
        imChat?.markAllMessagesAsRead()
    }

    private var cbChat: CBChat? {
        get async {
            guard let imChat else {
                return nil
            }
            return await CBChatRegistry.shared.chats[.guid(imChat.guid)]
        }
    }

    public func sendReturningRaw(message createMessage: CreateMessage, from: String? = nil) async throws -> IMMessage {
        guard let imChat, let service else {
            throw BarcelonaError(code: 500, message: "No imChat or service to send with for \(self.id)")
        }

        let log = Logger(label: "Chat")

        if let cbChat = await cbChat {
            // If we're targeting the SMS service and call imChat.refreshServiceForSending(), it'll probably retarget to iMessage,
            // which we distinctly don't want it to do. Plus, we're implementing this to solve BE-7179, which has only happened
            // over iMessage as far as we can tell, so we don't need to work with SMS
            if service == .iMessage {
                imChat.refreshServiceForSending()

                let newService = imChat.account.service?.id
                if newService != service {
                    log.warning(
                        "Refreshing IMChat \(String(describing: imChat.guid)) caused service to change from \(service) to \(String(describing: newService)); forcibly retargeting to iMessage"
                    )

                    guard let account = IMAccountController.shared.__activeIMessageAccount else {
                        log.warning(
                            "Couldn't get IMAccount for iMessage and thus couldn't retarget IMChat \(String(describing: imChat.guid)) to iMessage instead of SMS. Bailing."
                        )
                        throw BarcelonaError(
                            code: 500,
                            message: "Your iMessage account claims to not exist; please contact support."
                        )
                    }

                    imChat._setAccount(account, locally: true)
                }
            }

            log.info("Using CBChat for sending per feature flags", source: "MessageSending")
            return try await cbChat.send(message: createMessage, guid: imChat.guid, service: service)
        }

        imChat.refreshServiceForSendingIfNeeded()

        //let message = try createMessage.imMessage(inChat: self.id, service: service)
        let message = try createMessage.newIMMessage(inChat: self.id, service: service)

        Chat.delegate?.chat(self, willSendMessages: [message], fromCreateMessage: createMessage)

        Thread.main.sync {
            markAsRead()
            let imChat = imChat
            if let from = from {
                imChat.lastAddressedHandleID = from
            }
            imChat.send(message)
        }

        return message
    }

    public func send(message createMessage: CreateMessage, from: String? = nil) async throws -> Message {
        guard let imChat, let service else {
            throw BarcelonaError(code: 500, message: "No IMChat or service for \(id)")
        }

        return Message(
            messageItem: try await sendReturningRaw(message: createMessage, from: from)._imMessageItem,
            chatID: imChat.chatIdentifier,
            service: service
        )
    }

    public func tapback(_ creation: TapbackCreation, metadata: Message.Metadata? = nil) async throws -> Message {
        markAsRead()
        guard let imChat, let service else {
            throw BarcelonaError(code: 500, message: "No IMChat or service for \(id)")
        }

        let message = try await imChat.tapback(
            guid: creation.message,
            itemGUID: creation.item,
            type: creation.type,
            overridingItemType: nil,
            metadata: metadata
        )

        return Message(messageItem: message._imMessageItem, chatID: imChat.chatIdentifier, service: service)
    }
}
