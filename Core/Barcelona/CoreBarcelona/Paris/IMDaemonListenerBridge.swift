//
//  IMDaemonListenerBridge.swift
//  Barcelona
//
//  Created by Joonas Myhrberg on 26.2.2023.
//

import Foundation
import IMCore
import IMFoundation
import IMSharedUtilities
import Logging

/// Bridges delegate methods form `IMDaemonListenerProtocol` to `CBChatRegistry`.
class IMDaemonListenerBridge: NSObject, IMDaemonListenerProtocol, @unchecked Sendable {

    // MARK: - Properties

    private weak var registry: CBChatRegistry!

    private let log = Logger(label: "IMDaemonListenerBridge")

    init(registry: CBChatRegistry) {
        log.debug("Creating IMDaemonListenerBridge with registry \(registry)")
        self.registry = registry
    }

    deinit {
        log.debug("IMDaemonListenerBridge deinit")
    }

    // MARK: - IMDaemonListenerProtocol

    func setupComplete(_ success: Bool, info: [AnyHashable: Any]!) {
        log.trace("IMDaemonListenerBridge.setupComplete(_:info:)")
        Task {
            await registry.setupComplete(success, info: info)
        }
    }

    func chat(_ persistentIdentifier: String!, updated updateDictionary: [AnyHashable: Any]!) {
        log.trace("IMDaemonListenerBridge.chat(_:updated:)")
        Task {
            await registry.chat(persistentIdentifier, updated: updateDictionary)
        }
    }

    func chat(_ persistentIdentifier: String!, propertiesUpdated properties: [AnyHashable: Any]!) {
        log.trace("IMDaemonListenerBridge.chat(_:propertiesUpdated:)")
        Task {
            await registry.chat(persistentIdentifier, propertiesUpdated: properties)
        }
    }

    func chat(_ persistentIdentifier: String!, engramIDUpdated engramID: String!) {
        log.trace("IMDaemonListenerBridge.chat(_:engramIDUpdated:)")
        Task {
            await registry.chat(persistentIdentifier, engramIDUpdated: engramID)
        }
    }

    func chat(_ guid: String!, lastAddressedHandleUpdated lastAddressedHandle: String!) {
        log.trace("IMDaemonListenerBridge.chat(_:lastAddressedHandleUpdated:)")
        Task {
            await registry.chat(guid, lastAddressedHandleUpdated: lastAddressedHandle)
        }
    }

    func chatLoaded(withChatIdentifier chatIdentifier: String!, chats chatDictionaries: [Any]!) {
        log.trace("IMDaemonListenerBridge.chatLoaded(withChatIdentifier:chats:)")
        Task {
            await registry.chatLoaded(withChatIdentifier: chatIdentifier, chats: chatDictionaries)
        }
    }

    func lastMessage(forAllChats chatIDToLastMessageDictionary: [AnyHashable: Any]!) {
        log.trace("IMDaemonListenerBridge.lastMessage(forAllChats:)")
        Task {
            await registry.lastMessage(forAllChats: chatIDToLastMessageDictionary)
        }
    }

    func service(
        _ serviceID: String!,
        chat chatIdentifier: String!,
        style chatStyle: IMChatStyle,
        messagesUpdated messages: [[AnyHashable: Any]]!
    ) {
        log.trace("IMDaemonListenerBridge.service(_:chat:style:messagesUpdated:)")
        Task {
            await registry.service(serviceID, chat: chatIdentifier, style: chatStyle, messagesUpdated: messages)
        }
    }

    func account(
        _ accountUniqueID: String!,
        chat chatIdentifier: String!,
        style chatStyle: IMChatStyle,
        chatProperties properties: [AnyHashable: Any]!,
        error: Error!
    ) {
        log.trace("IMDaemonListenerBridge.account(_:chat:style:chatProperties:error:)")
        Task {
            await registry
                .account(
                    accountUniqueID,
                    chat: chatIdentifier,
                    style: chatStyle,
                    chatProperties: properties,
                    error: error
                )
        }
    }

    func account(
        _ accountUniqueID: String!,
        chat chatIdentifier: String!,
        style chatStyle: IMChatStyle,
        chatProperties properties: [AnyHashable: Any]!,
        notifySentMessage msg: IMMessageItem!,
        sendTime: NSNumber!
    ) {
        log.trace("IMDaemonListenerBridge.account(_:chat:style:chatProperties:notifySentMessage:sendTime:)")
        Task {
            await registry
                .account(
                    accountUniqueID,
                    chat: chatIdentifier,
                    style: chatStyle,
                    chatProperties: properties,
                    notifySentMessage: msg,
                    sendTime: sendTime
                )
        }
    }

    func account(
        _ accountUniqueID: String!,
        chat chatIdentifier: String!,
        style chatStyle: IMChatStyle,
        chatProperties properties: [AnyHashable: Any]!,
        groupID: String!,
        chatPersonCentricID personCentricID: String!,
        messagesReceived messages: [IMItem]!,
        messagesComingFromStorage fromStorage: Bool
    ) {
        log.trace("IMDaemonListenerBridge.account(_:chat:style:chatProperties:groupID:chatPersonCentricID:messagesReceived:messagesComingFromStorage:)")
        Task {
            await registry
                .account(
                    accountUniqueID,
                    chat: chatIdentifier,
                    style: chatStyle,
                    chatProperties: properties,
                    groupID: groupID,
                    chatPersonCentricID: personCentricID,
                    messagesReceived: messages,
                    messagesComingFromStorage: fromStorage
                )
        }
    }

    func account(
        _ accountUniqueID: String!,
        chat chatIdentifier: String!,
        style chatStyle: IMChatStyle,
        chatProperties properties: [AnyHashable: Any]!,
        groupID: String!,
        chatPersonCentricID personCentricID: String!,
        statusChanged status: FZChatStatus,
        handleInfo: [Any]!
    ) {
        log.trace("IMDaemonListenerBridge.account(_:chat:style:chatProperties:groupID:chatPersonCentricID:statusChanged:handleInfo:)")
        Task {
            await registry
                .account(
                    accountUniqueID,
                    chat: chatIdentifier,
                    style: chatStyle,
                    chatProperties: properties,
                    groupID: groupID,
                    chatPersonCentricID: personCentricID,
                    statusChanged: status,
                    handleInfo: handleInfo
                )
        }
    }

    func account(
        _ accountUniqueID: String!,
        chat chatIdentifier: String!,
        style chatStyle: IMChatStyle,
        chatProperties properties: [AnyHashable: Any]!,
        groupID: String!,
        chatPersonCentricID personCentricID: String!,
        messagesReceived messages: [IMItem]!
    ) {
        log.trace("IMDaemonListenerBridge.account(_:chat:style:chatProperties:groupID:chatPersonCentricID:messagesReceived:)")
        Task {
            await registry
                .account(
                    accountUniqueID,
                    chat: chatIdentifier,
                    style: chatStyle,
                    chatProperties: properties,
                    groupID: groupID,
                    chatPersonCentricID: personCentricID,
                    messagesReceived: messages
                )
        }
    }

    func account(
        _ accountUniqueID: String!,
        chat chatIdentifier: String!,
        style chatStyle: IMChatStyle,
        chatProperties properties: [AnyHashable: Any]!,
        groupID: String!,
        chatPersonCentricID personCentricID: String!,
        messageReceived msg: IMItem!
    ) {
        log.trace("IMDaemonListenerBridge.account(_:chat:style:chatProperties:groupID:chatPersonCentricID:messageReceived:)")
        Task {
            await registry
                .account(
                    accountUniqueID,
                    chat: chatIdentifier,
                    style: chatStyle,
                    chatProperties: properties,
                    groupID: groupID,
                    chatPersonCentricID: personCentricID,
                    messageReceived: msg
                )
        }
    }

    func account(
        _ accountUniqueID: String!,
        chat chatIdentifier: String!,
        style chatStyle: IMChatStyle,
        chatProperties properties: [AnyHashable: Any]!,
        groupID: String!,
        chatPersonCentricID personCentricID: String!,
        messageSent msg: IMMessageItem!
    ) {
        log.trace("IMDaemonListenerBridge.account(_:chat:style:chatProperties:groupID:chatPersonCentricID:messageSent:)")
        Task {
            await registry
                .account(
                    accountUniqueID,
                    chat: chatIdentifier,
                    style: chatStyle,
                    chatProperties: properties,
                    groupID: groupID,
                    chatPersonCentricID: personCentricID,
                    messageSent: msg
                )
        }
    }

    func account(
        _ accountUniqueID: String!,
        chat chatIdentifier: String!,
        style chatStyle: IMChatStyle,
        chatProperties properties: [AnyHashable: Any]!,
        updateProperties update: [AnyHashable: Any]!
    ) {
        log.trace("IMDaemonListenerBridge.account(_:chat:style:chatProperties:updateProperties:)")
        Task {
            await registry
                .account(
                    accountUniqueID,
                    chat: chatIdentifier,
                    style: chatStyle,
                    chatProperties: properties,
                    updateProperties: update
                )
        }
    }

    func account(
        _ accountUniqueID: String!,
        chat chatIdentifier: String!,
        style chatStyle: IMChatStyle,
        chatProperties properties: [AnyHashable: Any]!,
        messageUpdated msg: IMItem!
    ) {
        log.trace("IMDaemonListenerBridge.account(_:chat:style:chatProperties:messageUpdated:)")
        Task {
            await registry
                .account(
                    accountUniqueID,
                    chat: chatIdentifier,
                    style: chatStyle,
                    chatProperties: properties,
                    messageUpdated: msg
                )
        }
    }

    func account(
        _ accountUniqueID: String!,
        chat chatIdentifier: String!,
        style chatStyle: IMChatStyle,
        chatProperties properties: [AnyHashable: Any]!,
        messagesUpdated messages: [NSObject]!
    ) {
        log.trace("IMDaemonListenerBridge.account(_:chat:style:chatProperties:messagesUpdated:)")
        Task {
            await registry
                .account(
                    accountUniqueID,
                    chat: chatIdentifier,
                    style: chatStyle,
                    chatProperties: properties,
                    messagesUpdated: messages
                )
        }
    }

    func loadedChats(_ chats: [[AnyHashable: Any]]!, queryID: String!) {
        log.trace("IMDaemonListenerBridge.loadedChats(_:queryID:)")
        Task {
            await registry.loadedChats(chats, queryID: queryID)
        }
    }

    func loadedChats(_ chats: [[AnyHashable: Any]]!) {
        log.trace("IMDaemonListenerBridge.loadedChats(_:)")
        Task {
            await registry.loadedChats(chats)
        }
    }
}
