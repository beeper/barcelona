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
import IMDaemonCore
import IMDPersistence
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
        BLCreateGUID(blFacingService, CBChatStyle(chatStyle), chatIdentifier)
    }
}

// (bl-api-exposed)
public class Chat {
    public init(_ backing: IMChat) {
        joinState = backing.joinState
        roomName = backing.roomName
        displayName = backing.displayName
        id = backing.chatIdentifier
        participants = backing.recentParticipantHandleIDs
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
    public static func directMessage(withHandleID handleID: String, service: IMServiceStyle) async -> Chat? {
        let imchat = await IMChat.directMessage(withHandleID: handleID, service: service)
        if let imchat, (imchat.chatIdentifier != handleID || imchat.account.service?.id != service) {
            log.warning("Chat.directMessage returned a chat with incorrect details (\(imchat.guid) vs \(handleID) and \(String(describing: service.service.name)))")
            return nil
        }

        return imchat.map(Chat.init)
    }

    public static func groupChat(withHandleIDs handleIDs: [String], service: IMServiceStyle) async -> Chat? {
        await IMChat.groupChat(withHandleIDs: handleIDs, service: service).map(Chat.init)
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

public func BLCreateGUID(_ service: IMServiceStyle, _ chatStyle: CBChatStyle?, _ chatID: String) -> String {
    return BLCreateGUID(service.service.name ?? service.rawValue, chatStyle, chatID)
}

public func BLCreateGUID(_ service: String, _ chatStyle: CBChatStyle?, _ chatID: String) -> String {
    let style = chatStyle ?? CBChatStyle.from(chatIdentifier: chatID)
    return "\(service);\(style == .group ? "+" : "-");\(chatID)"
}

public func getIMServiceStyleForChatGuid(_ chatGuid: String) -> IMServiceStyle {
    return ParsedGUID(rawValue: chatGuid).service == "iMessage" ? IMServiceStyle.iMessage : .SMS
}

@MainActor
public func getIMChatForChatGuid(_ chatGuid: String) async -> IMChat? {
    if let chat = IMChatRegistry.shared.existingChat(withGUID: chatGuid) {
        guard chat.guid == chatGuid else {
            let goodChat = loadChatMatchingGUID(chatGuid, badChat: chat)
            log.warning("Chat retrieved from registry has an incorrect guid (\(chat.guid) vs \(chatGuid)), chatMatchingGUID returned \(goodChat?.guid ?? "nil")")

            return goodChat
        }
        return chat
    } else {
        let parsed = ParsedGUID(rawValue: chatGuid)

        let service = parsed.service == "iMessage" ? IMServiceStyle.iMessage : .SMS
        let id = parsed.last

        // If it's an instantMessage GUID
        if parsed.style == "-" {
            guard let imChat = await IMChat.directMessage(withHandleID: id, service: service) else {
                log.warning("Couldn't create direct message with handle \(id) on service \(service.rawValue)")
                return nil
            }

            log.warning("No chat found for \(chatGuid) but using directMessage chat for \(id)")

            guard imChat.guid == chatGuid else {
                log.warning("getIMChatForChatGuid pulled an imChat with a mismatching GUID (\(imChat.guid) vs expected \(chatGuid))")
                return nil
            }

            return imChat
        }
    }

    log.warning("No chat found for \(chatGuid)")
    return nil
}

public func loadChatMatchingGUID(_ guid: String, badChat: IMChat) -> IMChat? {
    let sharedRegistry = IMChatRegistry.shared
    let checkChat: () -> IMChat? = {
        if let chat = sharedRegistry.existingChat(withGUID: guid), chat.guid == guid {
            return chat
        }

        let allChats = sharedRegistry.allChats
        if let chat = allChats.first(where: { $0.guid == guid }) {
            return chat
        }

        return allChats.first { chat in
            chat._guids.contains { $0 == guid }
        }
    }

    if let chat = checkChat() {
        return chat
    }

    let chatID = ParsedGUID(rawValue: guid).last
    log.warning("Couldn't get chat \(guid) from `allChats`; trying to load chatID \(chatID) from IMDChatRegistry")

    // calling IMDSetIsRunningInDatabaseServerProcess is only to see if XPC is what is making existingChat(withGUID:) not work.
    // See, if IMDChatRegistry doesn't have an IMDChat cached, it'll ask its IMDChatStore to grab it and return it. If
    // `IMDIsRunningInDatabaseServerProcess() == 1`, IMDChatStore will read directly from chat.db to grab it. Else, it'll do
    // an XPC call, which obviously is much more fraught towards failure. If we add this and calling existingChat becomes much
    // more reliable, it's a weird XPC issue and we can start debugging that.
    // However, setting this can cause issues ('cause we're telling the system that we only have read access to the db when
    // that may not be true), so we reset it immediately after and hope we don't cause a race condition
    IMDSetIsRunningInDatabaseServerProcess(1)

    guard let imdchat = IMDChatRegistry.sharedInstance().existingChat(withGUID: guid) else {
        log.warning("Can't get IMDChat for guid \(guid); failing")
        return nil
    }

    IMDSetIsRunningInDatabaseServerProcess(0)

    guard let dict = imdchat.chatProperties() else {
        log.warning("Can't get dictionary representation for IMDChat \(imdchat)")
        return nil
    }

    log.warning("Processing chat dictionaryRepresentation for guid \(guid) and hoping it returns a chat")
    guard let cachedChats = sharedRegistry.value(forKey: "_chatGUIDToChatMap") as? NSMutableDictionary else {
        log.error("The _chatGUIDToChatMap dictionary no longer exists; something is off or maybe the process is just starting up (probably the former)")
        return nil
    }

    // So, normally once we run into this situation, the cached map has the same
    // object stored for both the good and bad guid. So we need to first remove
    // them both from the map so that when we load in the chat's properties
    // (down in `_processLoadedChatDictionaries`), it doesn't find the already-
    // existing IMChat to point to instead. So once we remove them, we load in
    // the properties, it creates a new IMChat with the correct properties and
    // such, and then we put the old one back in the map so the bad guid will
    // still work.
    cachedChats.removeObject(forKey: guid)
    let oldChat = cachedChats[badChat.guid]
    cachedChats.removeObject(forKey: badChat.guid)

    sharedRegistry._processLoadedChatDictionaries([dict])

    cachedChats[badChat.guid] = oldChat
    return checkChat()
}

@MainActor
public func getIMChatForGroupID(_ groupID: String) async -> IMChat? {
    IMChatRegistry.shared.existingChat(withGroupID: groupID)
}

extension IMChat {
    @MainActor
    public static func directMessage(withHandleID handleID: String, service: IMServiceStyle) async -> IMChat? {
        IMChatRegistry.shared.chat(for: bestHandle(forID: handleID, service: service))
    }

    @MainActor
    public static func groupChat(withHandleIDs handleIDs: [String], service: IMServiceStyle) async -> IMChat? {
        let handles = handleIDs.map { bestHandle(forID: $0, service: service) }
        return IMChatRegistry.shared.chat(for: handles)
    }
}

// MARK: - Message sending
extension IMChat {
    @MainActor public func send(message: IMMessage) {
        send(message)
    }

    public func send(message: IMMessageItem) async {
        await send(message: IMMessage(fromIMMessageItem: message, sender: nil, subject: nil))
    }

    public func send(message: CreateMessage) async -> IMMessage {
        let message = message.imMessage(inChat: self)
        await send(message: message)
        return message
    }
}
