//
//  Message.swift
//  imcore-rest
//
//  Created by Eric Rabil on 7/24/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

public extension Array where Element == String {
    func er_chatItems(in chat: String) -> Promise<[ChatItem], Error> {
        IMMessage.messages(withGUIDs: self)
    }
}

private func CBExtractThreadOriginatorAndPartFromIdentifier(_ identifier: String) -> (String, Int)? {
    let parts = identifier.split(separator: ",")
    
    guard parts.count > 2 else {
        return nil
    }
    
    guard let part = Int(parts[1]), let identifier = parts.last else {
        return nil
    }
    
    return (String(identifier), part)
}

private extension IngestionContext {
    func ingest(_ items: [NSObject]) -> [ChatItem] {
        items.map {
            ChatItemType.ingest(object: $0, context: self)
        }
    }
}

public struct Message: ChatItemOwned, CustomDebugStringConvertible, Hashable {
    static func message(withGUID guid: String) -> Promise<Message?, Error> {
        IMMessage.message(withGUID: guid).then {
            $0 as? Message
        }
    }
    
    static func messages(withGUIDs guids: [String], in chat: String? = nil) -> Promise<[Message], Error> {
        IMMessage.messages(withGUIDs: guids, in: chat).then {
            $0.compactMap {
                $0 as? Message
            }
        }
    }
    
    public static func associatedMessages(withGUID guid: String) -> Promise<[Message], Error> {
        DBReader.shared.associatedMessages(with: guid)
    }
    
    public static func messages(matching query: String, limit: Int) -> Promise<[Message], Error> {
        DBReader().messages(matching: query, limit: limit)
    }
    
    public static let ingestionClasses: [NSObject.Type] = [IMItem.self, IMMessage.self, IMMessageItem.self]
    
    public init?(ingesting item: NSObject, context: IngestionContext) {
        switch item {
        case let item as IMMessageItem:
            if let message = context.message {
                self.init(item, message: message, items: context.ingest(item._newChatItems()), chatID: context.chatID)
            } else {
                self.init(item, items: context.ingest(item._newChatItems()), chatID: context.chatID)
            }
        case let item as IMMessage:
            self.init(item, items: context.ingest(item._imMessageItem._newChatItems()), chatID: context.chatID)
        default:
            return nil
        }
    }

    init(_ item: IMItem, transcriptRepresentation: ChatItem, chatID: String?) {
        id = item.guid
        fromMe = item.isFromMe
        subject = nil
        isSOS = false
        isTypingMessage = false
        isCancelTypingMessage = false
        isDelivered = true
        isAudioMessage = false
        flags = 0x5
        items = [transcriptRepresentation.eraseToAnyChatItem()]
        service = item.resolveServiceStyle(inChat: chatID)
        sender = item.resolveSenderID(inService: service)
        associatedMessageID = item.associatedMessageGUID() as? String
        fileTransferIDs = []
        item.bareReceipt.assign(toMessage: &self)
        
        self.load(item: item, chatID: chatID)
    }
    
    init(_ backing: IMMessageItem, message: IMMessage, items chatItems: [ChatItem], chatID messageChatID: String?) {
        id = message.guid
        chatID = messageChatID
        fromMe = message.isFromMe
        service = backing.resolveServiceStyle(inChat: chatID)
        sender = message.resolveSenderID(inService: service)
        subject = message.subject?.id
        messageSubject = backing.subject ?? message.messageSubject?.string
        isSOS = backing.isSOS
        isTypingMessage = backing.isTypingMessage || chatItems.contains {
            $0 is TypingItem
        }
        
        isCancelTypingMessage = backing.isCancelTypingMessage()
        isDelivered = backing.isDelivered
        isAudioMessage = backing.isAudioMessage
        items = chatItems.map { $0.eraseToAnyChatItem() }
        flags = backing.flags
        associatedMessageID = message.associatedMessageGUID ?? backing.associatedMessageGUID() as? String
        fileTransferIDs = message.fileTransferGUIDs
        
        if let chatID = chatID, let chat = IMChat.resolve(withIdentifier: chatID) {
            description = try? message.description(forPurpose: 0x2, inChat: chat)
        }
        
        // load timestamps
        message.receipt.merging(receipt: backing.receipt).assign(toMessage: &self)
        self.load(message: message)
        self.load(item: backing, chatID: chatID)
    }
    
    init(_ backing: IMMessageItem, items: [ChatItem], chatID: String?) {
        self.init(backing, message: backing.message() ?? IMMessage.message(fromUnloadedItem: backing)!, items: items, chatID: chatID)
    }
    
    init(_ message: IMMessage, items: [ChatItem], chatID: String?) {
        self.init(message._imMessageItem, message: message, items: items, chatID: chatID)
    }
    
    private mutating func load(message: IMMessage) {
        if #available(iOS 14, macOS 10.16, watchOS 7, *) {
            if let rawThreadIdentifier = message.threadIdentifier(), let (threadIdentifier, threadOriginatorPart) = CBExtractThreadOriginatorAndPartFromIdentifier(rawThreadIdentifier) {
                self.threadIdentifier = threadIdentifier
                self.threadOriginator = threadIdentifier
                self.threadOriginatorPart = threadOriginatorPart
            }
        }
    }
    
    public var id: String
    public var chatID: String?
    public var fromMe: Bool?
    public var time: Double?
    public var sender: String?
    public var subject: String?
    public var timeDelivered: Double = 0
    public var timePlayed: Double = 0
    public var timeRead: Double = 0
    public var messageSubject: String?
    public var isSOS: Bool
    public var isTypingMessage: Bool
    public var isCancelTypingMessage: Bool
    public var isDelivered: Bool
    public var isAudioMessage: Bool
    public var description: String?
    public var flags: UInt64
    public var items: [AnyChatItem]
    public var service: IMServiceStyle
    public var fileTransferIDs: [String]
    public var associatedMessageID: String?
    public var threadIdentifier: String?
    public var threadOriginator: String?
    public var threadOriginatorPart: Int?
    
    public var debugDescription: String {
        String(format: "Message(id=%@,sender=%@,typing=%d,items=[%@])", id ?? "(nil)", sender ?? "(nil)", isTypingMessage, items.map(\.debugDescription).joined(separator: ", "))
    }
    
    public var imChat: IMChat? {
        guard let chatID = chatID else {
            return nil
        }
        
        return IMChat.resolve(withIdentifier: chatID)
    }
    
    public var chat: Chat? {
        imChat?.representation
    }
    
    public var associableItemIDs: [String] {
        items.filter { item in
            item.type == .text || item.type == .attachment || item.type == .plugin
        }.map(\.id)
    }
    
    public var type: ChatItemType {
        .message
    }
}
