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

public enum ChatStyle: UInt8 {
    case group = 0x2b
    case single = 0x2d
}

public protocol BulkChatRepresentatable {
    var chats: [Chat] { get set }
}

public enum MessagePartType: String, Codable {
    case text
    case attachment
    case breadcrumb
}

public struct MessagePart: Codable {
    public var type: MessagePartType
    public var details: String
    public var attributes: [TextPartAttribute]?
    
    public init(type: MessagePartType, details: String, attributes: [TextPartAttribute]? = nil) {
        self.type = type
        self.details = details
        self.attributes = attributes
    }
}

public protocol MessageIdentifiable {
    var id: String { get set }
}

public protocol ChatConfigurationRepresentable {
    var readReceipts: Bool { get set }
    var ignoreAlerts: Bool { get set }
    var groupPhotoID: String? { get set }
}

public struct ChatConfigurationRepresentation: Codable, Hashable, ChatConfigurationRepresentable {
    public var id: String
    public var readReceipts: Bool
    public var ignoreAlerts: Bool
    public var groupPhotoID: String?
}

public struct DeleteMessage: Codable, MessageIdentifiable {
    public var id: String
    public var parts: [Int]?
    
    public init(id: String, parts: [Int]? = nil) {
        self.id = id
        self.parts = parts
    }
}

extension MessageIdentifiable {
    public func chat() -> Promise<Chat?> {
        Chat.chat(forMessage: id)
    }
}

public struct DeleteMessageRequest: Codable {
    public var messages: [DeleteMessage]
    
    public init(messages: [DeleteMessage]) {
        self.messages = messages
    }
}

public struct TapbackCreation: Codable {
    public var item: String
    public var message: String
    public var type: Int
    
    public init(item: String, message: String, type: Int) {
        self.item = item
        self.message = message
        self.type = type
    }
}

private let log = Logger(category: "Chat")

public protocol ChatDelegate {
    func chat(_ chat: Chat, willSendMessages messages: [IMMessage], fromCreateMessage createMessage: CreateMessage) -> Void
    func chat(_ chat: Chat, willSendMessages messages: [IMMessage], fromCreatePluginMessage createPluginMessage: CreatePluginMessage) -> Void
}

public struct Chat: Codable, ChatConfigurationRepresentable, Hashable {
    public init(_ backing: IMChat) {
        joinState = backing.joinState
        roomName = backing.roomName
        displayName = backing.displayName
        id = backing.id
        participants = backing.recentParticipantHandleIDs
        unreadMessageCount = backing.unreadMessageCount
        messageFailureCount = backing.messageFailureCount
        service = backing.account?.service?.id
        lastMessage = backing.lastFinishedMessage?.description(forPurpose: 0x2, inChat: backing, senderDisplayName: backing.lastMessage?.sender._displayNameWithAbbreviation)
        lastMessageTime = (backing.lastFinishedMessage?.time.timeIntervalSince1970 ?? 0) * 1000
        style = backing.chatStyle
        readReceipts = backing.readReceipts
        ignoreAlerts = backing.ignoreAlerts
        groupPhotoID = backing.groupPhotoID
    }
    
    public static func chat(forMessage id: String) -> Promise<Chat?> {
        IMChat.chat(forMessage: id).maybeMap { chat in
            Chat(chat)
        }
    }
    
    public var id: String
    public var joinState: Int64
    public var roomName: String?
    public var displayName: String?
    public var participants: [String]
    public var unreadMessageCount: UInt64
    public var messageFailureCount: UInt64
    public var service: IMServiceStyle?
    public var lastMessage: String?
    public var lastMessageTime: Double
    public var style: UInt8
    public var readReceipts: Bool
    public var ignoreAlerts: Bool
    public var groupPhotoID: String?
    
    public static var delegate: ChatDelegate?
    
    public static var allChats: [Chat] {
        IMChatRegistry.shared.allChats.lazy.map(Chat.init(_:))
    }
    
    mutating func setTimeSortedParticipants(participants: [HandleTimestampRecord]) {
        self.participants = participants
            .map(\.handle_id)
            .filter(self.participants.contains)
    }
    
    public var imChat: IMChat {
        IMChat.resolve(withIdentifier: id)!
    }
    
    public var isTyping: Bool {
        get {
            imChat.localUserIsTyping
        }
        set {
            setTyping(newValue)
        }
    }
    
    
    public func setTyping(_ typing: Bool) {
        imChat.localUserIsTyping = typing
    }
    
    public func messages(before: String? = nil, limit: Int? = nil, beforeDate: Date? = nil) -> Promise<[Message]> {
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
        
        return BLLoadChatItems(withChatIdentifier: self.id, onServices: [.iMessage], beforeGUID: before, limit: limit).compactMap {
            $0 as? Message
        }
    }
    
    public func delete(message: DeleteMessage) -> Promise<Void> {
        let guid = message.id, parts = message.parts ?? []
        let fullMessage = parts.count == 0
        
        return IMMessage.lazyResolve(withIdentifier: guid).then { message -> Void in
            guard let message = message else {
                return
            }
            
            if fullMessage {
                IMDaemonController.shared().deleteMessage(withGUIDs: [guid], queryID: NSString.stringGUID())
            } else {
                let chatItems = message._imMessageItem._newChatItems()!
                
                let items: [IMChatItem] = parts.compactMap {
                    if chatItems.count <= $0 { return nil }
                    return chatItems[$0]
                }
                
                let newItem = self.imChat.chatItemRules._item(withChatItemsDeleted: items, fromItem: message._imMessageItem)!
                
                IMDaemonController.shared().updateMessage(newItem)
            }
        }
    }
    
    public func send(message options: CreatePluginMessage) throws -> [Message] {
        let message = try options.imMessage(inChat: self.id)
        
        Chat.delegate?.chat(self, willSendMessages: [message], fromCreatePluginMessage: options)
        
        RunLoop.main.schedule {
            self.imChat._sendMessage(message, adjustingSender: true, shouldQueue: true)
        }
        
        return _BLParseObjects([message], inChat: self.id)
            .compactMap {
                $0 as? Message
            }
    }
    
    public func send(message createMessage: CreateMessage) throws -> [Message] {
        let message = try createMessage.imMessage(inChat: self.id)
            
        let messages = message.messagesBySeparatingRichLinks() as? [IMMessage] ?? [message]
        
        Chat.delegate?.chat(self, willSendMessages: messages, fromCreateMessage: createMessage)
        
        messages.forEach {
            self.imChat.sendMessage($0)
        }
        
        return _BLParseObjects(messages, inChat: self.id).compactMap {
            $0 as? Message
        }
    }
    
    public func tapback(_ creation: TapbackCreation) -> Promise<Message?> {
        RunLoop.main.promise {
            try imChat.tapback(guid: creation.message, itemGUID: creation.item, type: creation.type, overridingItemType: nil)
        }.then {
            BLIngestObject($0, inChat: id)
        }.then {
            $0 as? Message
        }
    }
}

public extension Chat {
    var participantIDs: BulkHandleIDRepresentation {
        BulkHandleIDRepresentation(handles: participants)
    }
}

public extension Chat {
    var participantNames: [String] {
        participants.map {
            Registry.sharedInstance.imHandle(withID: $0)?.name ?? $0
        }
    }
}

func chatToRepresentation(_ backing: IMChat, skinny: Bool = false) -> Chat {
    return .init(backing)
}
