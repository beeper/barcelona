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

public extension IMChat {
    var blFacingService: String {
        account.serviceName
    }

    var blChatGUID: String {
        "\(blFacingService);\(isGroup ? "+" : "-");\(id)"
    }
}

// (bl-api-exposed)
public class Chat {
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
        imChat = backing
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
    public var imChat: IMChat
    
    /// All cached messages for this chat
    public internal(set) var messages: [String: CBMessage] = [:]

    public var guid: String {
        imChat.guid
    }

    public var blChatGUID: String? {
        imChat.blChatGUID
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
                imChat.markDirectRead(items: [message])
            }
    }
}

// MARK: - Querying
extension Chat {
    /// Returns a chat targeted at the appropriate service for a handleID
    @MainActor
    public static func directMessage(withHandleID handleID: String, service: IMServiceStyle) async -> Chat {
        // We have a service specified;
        try! await Chat(IMChatRegistry.shared.chat(for: bestHandle(forID: handleID, service: service)))
    }

    @MainActor
    public static func groupChat(withHandleIDs handleIDs: [String], service: IMServiceStyle) async -> Chat {
        let handles = handleIDs.map { bestHandle(forID: $0, service: service) }
        return await Chat(IMChatRegistry.shared.chat(for: handles))
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

public struct ParsedGUID: Codable, CustomStringConvertible {
    public var service: String?
    public var style: String?
    public var last: String

    public init(rawValue: String) {
        guard rawValue.contains(";") else {
            last = rawValue
            return
        }

        let split = rawValue.split(separator: ";")

        guard split.count == 3 else {
            last = rawValue
            return
        }

        service = String(split[0])
        style = String(split[1])
        last = String(split[2])
    }

    public var description: String {
        guard let service = service, let style = style else {
            return last
        }
        return "\(service);\(style);\(last)"
    }
}

public func getIMServiceStyleForChatGuid(_ chatGuid: String) -> IMServiceStyle {
    return ParsedGUID(rawValue: chatGuid).service == "iMessage" ? IMServiceStyle.iMessage : .SMS
}

@MainActor
public func getIMChatForChatGuid(_ chatGuid: String) async -> IMChat? {
    if let chat = IMChatRegistry.shared.existingChat(withGUID: chatGuid) {
        return chat
    } else {
        let parsed = ParsedGUID(rawValue: chatGuid)

        let service = parsed.service == "iMessage" ? IMServiceStyle.iMessage : .SMS
        let id = parsed.last

        if id.isPhoneNumber || id.isEmail || id.isBusinessID {
            let chat = await Chat.directMessage(withHandleID: id, service: service)
            log.warning("No chat found for \(chatGuid) but using directMessage chat for \(id)")
            return chat.imChat
        }
    }

    log.warning("No chat found for \(chatGuid)")
    return nil
}

@MainActor
public func getIMChatForGroupID(_ groupID: String) async -> IMChat? {
    IMChatRegistry.shared.existingChat(withGroupID: groupID)
}

// MARK: - Message sending
extension IMChat {
    @MainActor public func send(message: IMMessage) {
        send(message)
    }

    public func send(message: IMMessageItem) async {
        await send(message: IMMessage(fromIMMessageItem: message, sender: nil, subject: nil))
    }

    public func send(message: CreateMessage) async throws -> IMMessage {
        let message = try message.imMessage(inChat: self)
        await send(message: message)
        return message
    }
}
