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
class IMDaemonListenerBridge: NSObject, IMDaemonListenerProtocol {

    // MARK: - Properties

    weak var registry: CBChatRegistry?

    private let log = Logger(label: "CBChatRegistry")

    // MARK: - Methods

    func setupComplete(_ success: Bool, info: [AnyHashable: Any]!) {
        Task {
            await registry?.setupComplete(success, info: info)
        }
    }

    func chat(_ persistentIdentifier: String!, updated updateDictionary: [AnyHashable: Any]!) {
        Task {
            await registry?.chat(persistentIdentifier, updated: updateDictionary)
        }
    }

    func chat(_ persistentIdentifier: String!, propertiesUpdated properties: [AnyHashable: Any]!) {
        Task {
            await registry?.chat(persistentIdentifier, propertiesUpdated: properties)
        }
    }

    func chat(_ persistentIdentifier: String!, engramIDUpdated engramID: String!) {
        Task {
            await registry?.chat(persistentIdentifier, engramIDUpdated: engramID)
        }
    }

    func chat(_ guid: String!, lastAddressedHandleUpdated lastAddressedHandle: String!) {
        Task {
            await registry?.chat(guid, lastAddressedHandleUpdated: lastAddressedHandle)
        }
    }

    func chatLoaded(withChatIdentifier chatIdentifier: String!, chats chatDictionaries: [Any]!) {
        Task {
            await registry?.chatLoaded(withChatIdentifier: chatIdentifier, chats: chatDictionaries)
        }
    }

    func lastMessage(forAllChats chatIDToLastMessageDictionary: [AnyHashable: Any]!) {
        Task {
            await registry?.lastMessage(forAllChats: chatIDToLastMessageDictionary)
        }
    }

    func service(
        _ serviceID: String!,
        chat chatIdentifier: String!,
        style chatStyle: IMChatStyle,
        messagesUpdated messages: [[AnyHashable: Any]]!
    ) {
        Task {
            await registry?.service(serviceID, chat: chatIdentifier, style: chatStyle, messagesUpdated: messages)
        }
    }

    func account(
        _ accountUniqueID: String!,
        chat chatIdentifier: String!,
        style chatStyle: IMChatStyle,
        chatProperties properties: [AnyHashable: Any]!,
        error: Error!
    ) {
        Task {
            await registry?
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
        Task {
            await registry?
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
        Task {
            await registry?
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
        Task {
            await registry?
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
        Task {
            await registry?
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
        Task {
            await registry?
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
        Task {
            await registry?
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
        Task {
            await registry?
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
        Task {
            await registry?
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
        Task {
            await registry?
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
        Task {
            await registry?.loadedChats(chats, queryID: queryID)
        }
    }

    func loadedChats(_ chats: [[AnyHashable: Any]]!) {
        Task {
            await registry?.loadedChats(chats)
        }
    }
}
