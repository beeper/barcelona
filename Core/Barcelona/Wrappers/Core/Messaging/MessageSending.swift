//
//  MessageSending.swift
//  Barcelona
//
//  Created by Eric Rabil on 11/2/21.
//

import Foundation
import IMCore
import Swog
import Combine
import BarcelonaDB
import IMDPersistence

extension Date {
    static func now() -> Date { Date() }
}

internal extension IMChat {
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
    /// Stored instance variable on IMChat
    private var hasRefreshedServiceForSending: Bool {
        get { value(forKey: "_hasRefreshedServiceForSending") as! Bool }
        set { setValue(false, forKey: "_hasRefreshedServiceForSending") }
    }
    
    /// Refreshes the chat service for sending, runs once per chat.
    /// This is a no-op unless `CBFeatureFlags.refreshChatServices` is enabled.
    func refreshServiceForSendingIfNeeded() {
        guard CBFeatureFlags.refreshChatServices && !IMChat.regressionTesting_disableServiceRefresh else {
            return
        }
        if let lastMessageItem = lastFinishedMessageItem,
           lastMessageItem.isFinished, // message must be finished
           lastMessageItem.errorCode == .noError, // message must have no error
           let serviceStyle = lastMessageItem.serviceStyle,
           serviceStyle == .iMessage,
           let messageAccount = serviceStyle.account,
           self.account != messageAccount {
            // We are targeted to iMessage, but we don't really know why. Let's retarget to iMessage and see what IDS thinks.
            CLInfo("ERChat", "Previous message on service \(serviceStyle.rawValue) appears to have been successful, but my service is \(self.account?.serviceName ?? "nil"). I'm going to try my best to refresh the ID query.")
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
        let id = self.id, serviceName = account.serviceName ?? "nil"
        CLInfo("ERChat", "The resolved service for \(id) is currently \(serviceName)")
    }
}

public extension Chat {
    private func markAsRead() {
        if ProcessInfo.processInfo.environment.keys.contains("BARCELONA_GHOST_REPLIES") {
            return
        }
        imChat.markAllMessagesAsRead()
    }
    
    private var cbChat: CBChat? {
        CBChatRegistry.shared.chats[.guid(imChat.guid)]
    }
    
    func sendReturningRaw(message createMessage: CreateMessage, from: String? = nil) throws -> IMMessage {
        if CBFeatureFlags.useSendingV2, let cbChat = cbChat {
            CLInfo("MessageSending", "Using CBChat for sending per feature flags")
            return try cbChat.send(message: createMessage, guid: imChat.guid)
        }
        
        imChat.refreshServiceForSendingIfNeeded()
        
        let message = try createMessage.imMessage(inChat: self.id)
        
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
    
    func send(message createMessage: CreateMessage, from: String? = nil) throws -> Message {
        return Message(messageItem: try sendReturningRaw(message: createMessage, from: from)._imMessageItem, chatID: imChat.id)
    }
    
    func tapback(_ creation: TapbackCreation, metadata: Message.Metadata? = nil) throws -> Message {
        markAsRead()
        let message = try imChat.tapback(guid: creation.message, itemGUID: creation.item, type: creation.type, overridingItemType: nil, metadata: metadata)
        
        return Message(messageItem: message._imMessageItem, chatID: imChat.id)
    }
}
