//
//  Chat.swift
//  imcore-rest
//
//  Created by Eric Rabil on 7/23/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMSharedUtilities
import BarcelonaDB
import IMCore
import IMFoundation

private let log = Logger(category: "Chat")

public protocol ChatConfigurationRepresentable {
    var id: String { get }
    var readReceipts: Bool { get set }
    var ignoreAlerts: Bool { get set }
    var groupPhotoID: String? { get set }
}

public extension ChatConfigurationRepresentable {
    var configurationBits: ChatConfiguration {
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
    func chat(_ chat: Chat, willSendMessages messages: [IMMessage], fromCreateMessage createMessage: CreateMessage) -> Void
    func chat(_ chat: Chat, willSendMessages messages: [IMMessage], fromCreatePluginMessage createPluginMessage: CreatePluginMessage) -> Void
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
public struct Chat: Codable, ChatConfigurationRepresentable, Hashable {
    /// Useful for adding application-specific behavior, allows you to hook into different APIs on Chat (like sending)
    public static var delegate: ChatDelegate?
    
    public init(_ backing: IMChat) {
        joinState = backing.joinState
        roomName = backing.roomName
        displayName = backing.displayName
        id = backing.id
        participants = backing.recentParticipantHandleIDs
        unreadMessageCount = backing.unreadMessageCount
        messageFailureCount = backing.messageFailureCount
        service = backing.account?.service?.id
        lastMessage = backing.lastFinishedMessage?.description(forPurpose: .conversationList, in: backing, senderDisplayName: backing.lastMessage?.sender._displayNameWithAbbreviation)
        lastMessageTime = (backing.lastFinishedMessage?.time.timeIntervalSince1970 ?? 0) * 1000
        style = backing.chatStyle
        readReceipts = backing.readReceipts
        ignoreAlerts = backing.ignoreAlerts
        groupPhotoID = backing.groupPhotoID
    }
    
    /// Resolves the chat an IMMessage was sent from
    public static func chat(forMessage id: String) -> Promise<Chat?> {
        IMChat.chat(forMessage: id).maybeMap { chat in
            Chat(chat)
        }
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
        self.participants = participants
            .map(\.handle_id)
            .filter(self.participants.contains)
    }
    
    /// The underlying IMChat this Chat was created from
    public var imChat: IMChat {
        IMChat.resolve(withIdentifier: id)!
    }
}

// MARK: - Participants
public extension Chat {
    func addParticipants(_ participants: [String]) -> [String] {
        toggleParticipants(participants, add: true)
    }
    
    func removeParticipants(_ participants: [String]) -> [String] {
        toggleParticipants(participants, add: false)
    }
    
    func toggleParticipants(_ participants: [String], add: Bool) -> [String] {
        /*
         {"handles":["1234","eric@net.com"]}
         */
        let handles = participants.compactMap { Registry.sharedInstance.imHandle(withID: $0, onAccount: imChat.account) }
        
        var reasonMessage: IMMessage!
        
        let inviteText = add ? "Get in my van, kid." : "Goodbye, skank."
        
        if #available(iOS 14, macOS 10.16, watchOS 7, *) {
            reasonMessage = IMMessage.instantMessage(withText: NSAttributedString(string: inviteText), messageSubject: nil, flags: 0x5, threadIdentifier: nil)
        } else {
            reasonMessage = IMMessage.instantMessage(withText: NSAttributedString(string: inviteText), messageSubject: nil, flags: 0x5)
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
internal extension IMChat {
    func markDirectRead(items: [IMMessageItem]) {
        guard let serialized = CBCreateSerializedItemsFromArray(items), serialized.count > 0 else {
            return
        }
        
        let (identifiers, services) = querySpecifiers
        
        IMDaemonController.shared().markRead(
            forIDs: identifiers,
            style: chatStyle.rawValue,
            onServices: services,
            messages: serialized,
            clientUnreadCount: unreadMessageCount
        )
    }
}

public extension Chat {
    /// Marks a series of messages as read
    func markMessagesRead(withIDs messageIDs: [String]) {
        imChat.markDirectRead(items: BLLoadIMMessageItems(withGUIDs: messageIDs))
    }
    
    func markMessageAsRead(withID messageID: String) {
        BLLoadIMMessageItem(withGUID: messageID)
            .map { message in
                imChat.markDirectRead(items: [message])
            }
    }
}

// MARK: - Querying
public extension Chat {
    static var allChats: [Chat] {
        IMChatRegistry.shared.allChats.lazy.map(Chat.init(_:))
    }
    
    /// Returns a chat targeted at the appropriate service for a handleID
    static func directMessage(withHandleID handleID: String) -> Chat {
        Chat(IMChatRegistry.shared.chat(for: bestHandle(forID: handleID)))
    }
    
    /// Returns a chat targeted at the appropriate service for a handleID
    static func directMessage(withHandleID handleID: String, service: IMServiceStyle) -> Chat {
        Chat(IMChatRegistry.shared.chat(for: bestHandle(forID: handleID, service: service)))
    }
    
    /// Returns a chat targeted at the appropriate service for a set of handleIDs
    static func chat(withHandleIDs handleIDs: [String], service: IMServiceStyle? = nil) -> Chat {
        guard handleIDs.count > 0 else {
            preconditionFailure("chat(withHandleIDs) requires at least one handle ID to be non-null return type")
        }
        
        if handleIDs.count == 1 {
            if let service = service {
                return directMessage(withHandleID: handleIDs.first!, service: service)
            } else {
                return directMessage(withHandleID: handleIDs.first!)
            }
        } else {
            if let service = service, let account = service.account {
                return Chat(IMChatRegistry.shared.chat(for: handleIDs.map(account.imHandle(withID:))))
            } else {
                return Chat(IMChatRegistry.shared.chat(for: homogenousHandles(forIDs: handleIDs)))
            }
        }
    }
}

public extension Thread {
    func sync(_ block: @convention(block) @escaping () -> ()) {
        __im_performBlock(block, waitUntilDone: true)
    }
    
    func async(_ block: @convention(block) @escaping () -> ()) {
        __im_performBlock(block, waitUntilDone: false)
    }
}

// MARK: - Message Sending
public extension Chat {
    func messages(before: String? = nil, limit: Int? = nil, beforeDate: Date? = nil) -> Promise<[Message]> {
        if BLIsSimulation {
            let guids: [String] = imChat.chatItemRules._items().compactMap { item in
                if let chatItem = item as? IMChatItem {
                    return chatItem._item()?.guid
                } else if let item = item as? IMItem {
                    return item.guid
                }
                
                return nil
            }
            
            return IMMessage.messages(withGUIDs: guids, in: self.id).compactMap { message -> Message? in
                message as? Message
            }.sorted(usingKey: \.time, by: >)
        }
        
        log("Querying IMD for recent messages using chat fast-path")
        
        return BLLoadChatItems(withChatIdentifiers: [self.id], onServices: [.iMessage, .SMS], beforeGUID: before, limit: limit).compactMap {
            $0 as? Message
        }
    }
}

public extension Chat {
    var participantIDs: BulkHandleIDRepresentation {
        BulkHandleIDRepresentation(handles: participants)
    }

    var participantNames: [String] {
        participants.map {
            Registry.sharedInstance.imHandle(withID: $0)?.name ?? $0
        }
    }
}
