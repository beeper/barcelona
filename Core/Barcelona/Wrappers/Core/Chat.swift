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

protocol ChatConfigurationRepresentable {
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
    public func markMessageAsRead(withID messageID: String) {
        BLLoadIMMessageItem(withGUID: messageID)
            .map { message in
                imChat?.markDirectRead(items: [message])
            }
    }
}

// MARK: - Querying
extension Chat {
    /// Returns a chat targeted at the appropriate service for a handleID
    @MainActor
    public static func directMessage(withHandleID handleID: String, service: IMServiceStyle) async -> Chat {
        await Chat(IMChatRegistry.shared.chat(for: bestHandle(forID: handleID, service: service)))
    }
}

extension Thread {
    public func sync(_ block: @convention(block) @escaping () -> Void) {
        __im_performBlock(block, waitUntilDone: true)
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
