//
//  Chat.swift
//  imcore-rest
//
//  Created by Eric Rabil on 7/23/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import BarcelonaDB
import Foundation
import IMCore
import IMFoundation
import IMSharedUtilities
import Logging

private let log = Logger(label: "Chat")

public protocol ChatConfigurationRepresentable {
    var id: String { get }
    var readReceipts: Bool { get set }
    var ignoreAlerts: Bool { get set }
    var groupPhotoID: String? { get set }
}

extension ChatConfigurationRepresentable {
    public var configurationBits: ChatConfiguration {
        ChatConfiguration(id: id, readReceipts: readReceipts, ignoreAlerts: ignoreAlerts, groupPhotoID: groupPhotoID)
    }
}

public struct ChatConfiguration: Codable, Hashable, ChatConfigurationRepresentable {
    public var id: String
    public var readReceipts: Bool
    public var ignoreAlerts: Bool
    public var groupPhotoID: String?
}

public protocol ChatDelegate {
    func chat(_ chat: Chat, willSendMessages messages: [IMMessage], fromCreateMessage createMessage: CreateMessage)
    func chat(
        _ chat: Chat,
        willSendMessages messages: [IMMessage],
        fromCreatePluginMessage createPluginMessage: CreatePluginMessage
    )
}

extension IMChatStyle: Codable {
    public init(from decoder: Decoder) throws {
        self.init(rawValue: try RawValue.init(from: decoder))!
    }

    public func encode(to encoder: Encoder) throws {
        try rawValue.encode(to: encoder)
    }
}

extension IMChatStyle: Hashable {
    public static func == (lhs: IMChatStyle, rhs: IMChatStyle) -> Bool {
        lhs.rawValue == rhs.rawValue
    }

    public func hash(into hasher: inout Hasher) {
        rawValue.hash(into: &hasher)
    }
}

// (bl-api-exposed)
public struct Chat: Codable, ChatConfigurationRepresentable, Hashable, Sendable {
    /// Useful for adding application-specific behavior, allows you to hook into different APIs on Chat (like sending)
    public static var delegate: ChatDelegate?

    public init(_ backing: IMChat) async {
        joinState = backing.joinState
        roomName = backing.roomName
        displayName = backing.displayName
        id = backing.chatIdentifier
        participants = await backing.recentParticipantHandleIDs
        unreadMessageCount = backing.unreadMessageCount
        messageFailureCount = backing.messageFailureCount
        service = backing.account.service?.id
        lastMessage = backing.lastFinishedMessage?
            .description(
                forPurpose: .conversationList,
                in: backing,
                senderDisplayName: backing.lastMessage?.sender._displayNameWithAbbreviation
            )
        lastMessageTime = (backing.lastFinishedMessage?.time.timeIntervalSince1970 ?? 0) * 1000
        style = backing.chatStyle
        readReceipts = backing.readReceipts
        ignoreAlerts = backing.ignoreAlerts
        groupPhotoID = backing.groupPhotoID
    }

    public var id: String
    public var joinState: IMChatJoinState
    public var roomName: String?
    public var displayName: String?
    public var participants: [String]
    public var unreadMessageCount: UInt64
    public var messageFailureCount: UInt64
    public var service: IMServiceStyle?
    public var lastMessage: String?
    public var lastMessageTime: Double
    public var style: IMChatStyle
    public var readReceipts: Bool
    public var ignoreAlerts: Bool
    public var groupPhotoID: String?

    mutating func setTimeSortedParticipants(participants: [HandleTimestampRecord]) {
        self.participants =
            participants
            .map(\.handle_id)
            .filter(self.participants.contains)
    }

    /// The underlying IMChat this Chat was created from
    public var imChat: IMChat? {
        let chat = service.flatMap { IMChat.chat(withIdentifier: id, onService: $0, style: style.CBChat) }
        if chat == nil {
            log.warning(
                "IMChat.chat(withIdentifier: \(id), onService: \(String(describing: service)), style: \(style.CBChat)) returned nil"
            )
        }
        return chat
    }
}

// MARK: - Participants
extension Chat {
    public func addParticipants(_ participants: [String]) -> [String] {
        toggleParticipants(participants, add: true)
    }

    public func removeParticipants(_ participants: [String]) -> [String] {
        toggleParticipants(participants, add: false)
    }

    public func toggleParticipants(_ participants: [String], add: Bool) -> [String] {
        /*
         {"handles":["1234","eric@net.com"]}
         */
        guard let imChat else {
            return []
        }

        let handles = participants.compactMap {
            Registry.sharedInstance.imHandle(withID: $0, onAccount: imChat.account)
        }

        var reasonMessage: IMMessage!

        let inviteText = add ? "Get in my van, kid." : "Goodbye, skank."

        if #available(macOS 10.16, *) {
            reasonMessage = IMMessage.instantMessage(
                withText: NSAttributedString(string: inviteText),
                messageSubject: nil,
                flags: 0x5,
                threadIdentifier: nil
            )
        } else {
            reasonMessage = IMMessage.instantMessage(
                withText: NSAttributedString(string: inviteText),
                messageSubject: nil,
                flags: 0x5
            )
        }

        if add {
            if imChat.canAddParticipants(handles) {
                imChat.inviteParticipantsToiMessageChat(handles, reason: reasonMessage)
            }
        } else {
            imChat.removeParticipantsFromiMessageChat(handles, reason: reasonMessage)
        }

        return imChat.participantHandleIDs()
    }
}

// MARK: - Read Receipts
extension IMChat {
    func markDirectRead(items: [IMMessageItem]) {
        guard let serialized = CBCreateSerializedItemsFromArray(items), serialized.count > 0 else {
            return
        }

        let (identifiers, services) = querySpecifiers

        // We should figure this out better, but the situation for now is:
        // IMDaemonController.shared() returns an IMDaemonController.
        // IMDaemonController.sharedInstance() returns an IMDistributingProxy. What is that? Who knows. What does it do? Who knows.
        // But on Ventura,
        // IMDaemonController.shared().responds(to: #selector(IMRemoteDaemonProtocol.markRead(forIDs:style:onServices:messages:clientUnreadCount:)) == false, and
        // IMDaemonController.sharedInstance().responds(to: #selector(IMRemoteDaemonProtocol.markRead(forIDs:style:onServices:messages:clientUnreadCount:)) == true
        // We can also see this in the decompilation of `-[IMChatRegistry _chat_sendReadReceiptForAllMessages:]`, where it calls IMDaemonController.sharedInstance().markRead(...)
        var controller: IMRemoteDaemonProtocol {
            if #available(macOS 13.0, *) {
                return IMDaemonController.sharedInstance()
            } else {
                return IMDaemonController.shared()
            }
        }

        controller.markRead(
            forIDs: identifiers,
            style: chatStyle.rawValue,
            onServices: services,
            messages: serialized,
            clientUnreadCount: unreadMessageCount
        )
    }
}

extension Chat {
    /// Marks a series of messages as read
    public func markMessagesRead(withIDs messageIDs: [String]) {
        imChat?.markDirectRead(items: BLLoadIMMessageItems(withGUIDs: messageIDs))
    }

    public func markMessageAsRead(withID messageID: String) {
        BLLoadIMMessageItem(withGUID: messageID)
            .map { message in
                imChat?.markDirectRead(items: [message])
            }
    }
}

// MARK: - Querying
extension Chat {
    @MainActor
    public static var allChats: [Chat] {
        get async {
            await IMChatRegistry.shared.allChats.asyncMap { imChat in
                await Chat(imChat)
            }
        }
    }

    /// Returns a chat targeted at the appropriate service for a handleID
    @MainActor
    public static func directMessage(withHandleID handleID: String) async -> Chat {
        await Chat(IMChatRegistry.shared.chat(for: bestHandle(forID: handleID)))
    }

    /// Returns a chat targeted at the appropriate service for a handleID
    @MainActor
    public static func directMessage(withHandleID handleID: String, service: IMServiceStyle) async -> Chat {
        await Chat(IMChatRegistry.shared.chat(for: bestHandle(forID: handleID, service: service)))
    }

    /// Returns a chat targeted at the appropriate service for a set of handleIDs
    @MainActor
    public static func chat(withHandleIDs handleIDs: [String], service: IMServiceStyle) async -> Chat {
        guard handleIDs.count > 0 else {
            preconditionFailure("chat(withHandleIDs) requires at least one handle ID to be non-null return type")
        }

        if handleIDs.count == 1 {
            return await directMessage(withHandleID: handleIDs.first!, service: service)
        } else {
            if let account = service.account {
                return await Chat(IMChatRegistry.shared.chat(for: handleIDs.map(account.imHandle(withID:))))
            } else {
                return await Chat(IMChatRegistry.shared.chat(for: homogenousHandles(forIDs: handleIDs)))
            }
        }
    }

    public static func firstChatRegardlessOfService(withId chatId: String) async -> Chat? {
        for service in [IMServiceStyle.iMessage, IMServiceStyle.SMS] {
            if let chat = IMChat.chat(withIdentifier: chatId, onService: service, style: nil) {
                return await Chat(chat)
            }
        }
        return nil
    }
}

extension Thread {
    public func sync(_ block: @convention(block) @escaping () -> Void) {
        __im_performBlock(block, waitUntilDone: true)
    }

    public func async(_ block: @convention(block) @escaping () -> Void) {
        __im_performBlock(block, waitUntilDone: false)
    }
}

// MARK: - Message Sending
extension Chat {
    public func messages(before: String? = nil, limit: Int? = nil, beforeDate: Date? = nil) async throws -> [Message] {
        guard let service else {
            log.warning(
                "Cannot get messages(before: \(String(describing: before))) because service is nil; would not know what chat to check"
            )
            throw BarcelonaError(code: 500, message: "Chat.service is nil")
        }

        if BLIsSimulation {
            let guids: [String] =
                imChat?.chatItemRules._items()
                .compactMap { item in
                    if let chatItem = item as? IMChatItem {
                        return chatItem._item()?.guid
                    } else if let item = item as? IMItem {
                        return item.guid
                    }

                    return nil
                } ?? []

            return try await IMMessage.messages(withGUIDs: guids, in: self.id, service: service)
                .compactMap { message -> Message? in
                    message as? Message
                }
                .sorted(usingKey: \.time, by: >)
        }

        log.info("Querying IMD for recent messages using chat fast-path")

        return try await BLLoadChatItems(withChats: [(self.id, service)], beforeGUID: before, limit: limit)
            .compactMap {
                $0 as? Message
            }
    }
}

extension Chat {
    public var participantIDs: BulkHandleIDRepresentation {
        BulkHandleIDRepresentation(handles: participants)
    }

    public var participantNames: [String] {
        participants.map {
            Registry.sharedInstance.imHandle(withID: $0)?.name ?? $0
        }
    }
}
