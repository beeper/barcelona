//
//  Chat.swift
//  imcore-rest
//
//  Created by Eric Rabil on 7/23/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMSharedUtilities
import IMCore
import NIO
import os.log

public enum ChatStyle: UInt8 {
    case group = 0x2b
    case single = 0x2d
}

public protocol BulkChatRepresentatable {
    var chats: [Chat] { get set }
}

public struct BulkChatRepresentation: Codable, BulkChatRepresentatable {
    public init(_ chats: [IMChat]) {
        self.chats = chats.map {
            Chat($0)
        }
    }
    
    public init(_ chats: ArraySlice<IMChat>) {
        self.chats = chats.map {
            Chat($0)
        }
    }
    
    public init(_ chats: [Chat]) {
        self.chats = chats
    }
    
    public var chats: [Chat]
}

public struct ChatIDRepresentation: Codable {
    public init(chat: String) {
        self.chat = chat
    }
    
    public var chat: String
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
}

public protocol MessageIdentifiable {
    var id: String { get set }
}

public protocol ChatConfigurationRepresentable {
    var readReceipts: Bool { get set }
    var ignoreAlerts: Bool { get set }
}

public struct ChatConfigurationRepresentation: Codable, ChatConfigurationRepresentable {
    public var id: String
    public var readReceipts: Bool
    public var ignoreAlerts: Bool
}

public struct DeleteMessage: Codable, MessageIdentifiable {
    public var id: String
    public var parts: [Int]?
}

extension MessageIdentifiable {
    public func chat() -> EventLoopFuture<Chat?> {
        Chat.chat(forMessage: id)
    }
}

public struct DeleteMessageRequest: Codable {
    public var messages: [DeleteMessage]
}

private let log = OSLog(subsystem: "CoreBarcelona", category: "Chat")

public struct Chat: Codable, ChatConfigurationRepresentable {
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
    }
    
    public static func chat(forMessage id: String) -> EventLoopFuture<Chat?> {
        IMChat.chat(forMessage: id).map {
            if let chat = $0 {
                return Chat(chat)
            } else {
                return nil
            }
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
    
    mutating func setTimeSortedParticipants(participants: [HandleTimestampRecord]) {
        self.participants = participants.map {
            $0.handle_id
        }.including(array: self.participants)
    }
    
    public var imChat: IMChat {
        IMChat.resolve(withIdentifier: id)!
    }
    
    public func startTyping() {
        if imChat.localTypingMessageGUID == nil {
            imChat.setValue(NSString.stringGUID(), forKey: "_typingGUID")
            let message = IMMessage(sender: nil, time: nil, text: nil, fileTransferGUIDs: nil, flags: 0xc, error: nil, guid: imChat.localTypingMessageGUID, subject: nil)
            imChat._sendMessage(message, adjustingSender: true, shouldQueue: false)
        }
    }
    
    public func stopTyping() {
        if let typingGUID = imChat.localTypingMessageGUID {
            imChat.setValue(nil, forKey: "_typingGUID")
            let message = IMMessage(sender: nil, time: nil, text: nil, fileTransferGUIDs: nil, flags: 0xd, error: nil, guid: typingGUID, subject: nil)
            imChat.sendMessage(message)
        }
    }
    
    public func messages(before: String? = nil, limit: Int? = nil) -> EventLoopFuture<[ChatItem]> {
        if ERBarcelonaManager.isSimulation {
            let guids: [String] = imChat.chatItemRules._items().compactMap { item in
                if let chatItem = item as? IMChatItem {
                    return chatItem._item()?.guid
                } else if let item = item as? IMItem {
                    return item.guid
                }
                
                return nil
            }
            
            return IMMessage.messages(withGUIDs: guids, in: self.id, on: messageQuerySystem.next()).map { messages -> [ChatItem] in
                messages.sorted {
                    guard case .message(let message1) = $0, case .message(let message2) = $1 else {
                        return false
                    }
                    
                    return message1.time! > message2.time!
                }
            }
        }
        
        #if DEBUG
        let signpostID = OSSignpostID(log: log)
        os_signpost(.begin, log: .default, name: "Chat.messages():IMDCopy", signpostID: signpostID)
        #endif
        
        os_log("Querying IMD for recent messages using chat fast-path", log: log)
        
        return ERLoadAndParseIMDMessageRecordRefs(withChatIdentifier: self.id, onServices: [.iMessage], beforeGUID: before, limit: limit)
    }
    
    public func delete(message: DeleteMessage, on eventLoop: EventLoop) -> EventLoopFuture<Void> {
        let guid = message.id, parts = message.parts ?? []
        let fullMessage = parts.count == 0
        
        return IMMessage.imMessage(withGUID: guid, on: eventLoop).map { message -> Void in
            guard let message = message else {
                return
            }
            
            if fullMessage {
                IMDaemonController.shared()!.deleteMessage(withGUIDs: [guid], queryID: NSString.stringGUID())
            } else {
                let chatItems = message._imMessageItem._newChatItems()!
                
                let items: [IMChatItem] = parts.compactMap {
                    if chatItems.count <= $0 { return nil }
                    return chatItems[$0]
                }
                
                let newItem = self.imChat.chatItemRules._item(withChatItemsDeleted: items, fromItem: message._imMessageItem)!
                
                IMDaemonController.shared()!.updateMessage(newItem)
            }
        }
    }
    
    public func send(message options: CreatePluginMessage, on eventLoop: EventLoop? = nil) -> EventLoopFuture<BulkMessageRepresentation> {
        let eventLoop = eventLoop ?? messageQuerySystem.next()
        
        return options.imMessage(inChat: self.id, on: eventLoop).flatMap { message in
            DispatchQueue.main.async {
                self.imChat._sendMessage(message, adjustingSender: true, shouldQueue: true)
            }
            
            return ERIndeterminateIngestor.ingest(messageLike: message, in: self.id).flatMapThrowing { message in
                guard let message = message else {
                    throw BarcelonaError(code: 500, message: "Failed to construct represented message")
                }

                return BulkMessageRepresentation([message])
            }
        }
    }
    
    public func send(message createMessage: CreateMessage, on eventLoop: EventLoop? = nil) -> EventLoopFuture<BulkMessageRepresentation> {
        let eventLoop = eventLoop ?? messageQuerySystem.next()
        
        return createMessage.imMessage(inChat: self.id, on: eventLoop).flatMap { message in
            let promise = eventLoop.makePromise(of: BulkMessageRepresentation.self)
            
            DispatchQueue.main.async {
                guard let messages = message.messagesBySeparatingRichLinks() as? [IMMessage] else {
                    promise.fail(BarcelonaError(code: 500, message: "Failed to construct rich-link-separated IMMessages"))
                    return
                }
                
                messages.forEach {
                    self.imChat._sendMessage($0, adjustingSender: true, shouldQueue: true)
                }
                
                messages.bulkRepresentation(in: self.id).cascade(to: promise)
            }
            
            return promise.futureResult
        }
    }
}

public extension Chat {
    var participantIDs: BulkHandleIDRepresentation {
        BulkHandleIDRepresentation(handles: participants)
    }
}

func chatToRepresentation(_ backing: IMChat, skinny: Bool = false) -> Chat {
    return .init(backing)
}
