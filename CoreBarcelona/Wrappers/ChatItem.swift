//
//  File.swift
//  imcore-rest
//
//  Created by Eric Rabil on 7/24/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import Vapor

enum ChatItemType: String, Content {
    case status
    case attachment
    case participantChange
    case sender
    case date
    case message
    case associated
    case groupAction
    case plugin
    case text
    case phantom
    case typing
    case acknowledgment
    case groupTitle
}

protocol ChatItemRepresentation: Content {
    var guid: String? { get set }
    var chatGroupID: String? { get set }
    var fromMe: Bool? { get set }
    var time: Double? { get set }
}

extension ChatItemRepresentation {
    func tapbacks(on eventLoop: EventLoop) -> EventLoopFuture<[Message]> {
        let promise = eventLoop.makePromise(of: [Message].self)
        
        guard let guid = guid else {
            promise.succeed([])
            return promise.futureResult
        }
        
        DBReader(pool: db, eventLoop: eventLoop).associatedMessages(with: guid).whenComplete { result in
            switch result {
            case .success(let tapbacks):
                promise.succeed(tapbacks)
                break
            case .failure(let error):
                promise.fail(error)
                break
            }
        }
        
        return promise.futureResult
    }
}

extension ChatItemRepresentation {
    internal mutating func load(item: IMItem, chatGroupID chat: String?) {
        guid = item.guid
        chatGroupID = chat
        fromMe = item.isFromMe
        time = (item.time?.timeIntervalSince1970 ?? 0) * 1000
    }
    
    internal mutating func load(item: IMTranscriptChatItem, chatGroupID chat: String?) {
        
        guid = item.guid
        chatGroupID = chat
        fromMe = item.isFromMe
        time = ((item.transcriptDate ?? item._timeAdded())?.timeIntervalSince1970 ?? item._item()?.time?.timeIntervalSince1970 ?? 0) * 1000
    }
}

struct BulkChatItemRepresentation: Content {
    var items: [ChatItem]
}

public struct ChatItem: Content {
    let type: ChatItemType
    let item: Any?

    // MARK: Codable
    private enum CodingKeys: String, CodingKey {
        case type
        case payload
    }
    
    init(type: ChatItemType, item: Any?) {
        self.type = type
        self.item = item
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard let type = ChatItemType(rawValue: try container.decode(String.self, forKey: .type)) else {
            throw Abort(.badRequest)
        }
        
        self.type = type

        if let decode = ChatItem.decoders[type] {
            item = try decode(container)
        } else {
            item = nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(type, forKey: .type)

        if let payload = self.item {
            guard let encode = ChatItem.encoders[type] else {
                let context = EncodingError.Context(codingPath: [], debugDescription: "Invalid attachment: \(type).")
                throw EncodingError.invalidValue(self, context)
            }

            try encode(payload, &container)
        } else {
            try container.encodeNil(forKey: .payload)
        }
    }

    // MARK: Registration
    private typealias AttachmentDecoder = (KeyedDecodingContainer<CodingKeys>) throws -> Any
    private typealias AttachmentEncoder = (Any, inout KeyedEncodingContainer<CodingKeys>) throws -> Void

    private static var decoders: [ChatItemType: AttachmentDecoder] = [:]
    private static var encoders: [ChatItemType: AttachmentEncoder] = [:]

    static func register<A: Codable>(_ type: A.Type, for typeName: ChatItemType) {
        decoders[typeName] = { container in
            try container.decode(A.self, forKey: .payload)
        }

        encoders[typeName] = { payload, container in
            try container.encode(payload as! A, forKey: .payload)
        }
    }
    
    static func setup() {
        ChatItem.register(DateTranscriptChatItemRepresentation.self, for: .date)
        ChatItem.register(SenderTranscriptChatItemRepresentation.self, for: .sender)
        ChatItem.register(ParticipantChangeTranscriptChatItemRepresentation.self, for: .participantChange)
        ChatItem.register(AttachmentChatItemRepresentation.self, for: .attachment)
        ChatItem.register(StatusChatItemRepresentation.self, for: .status)
        ChatItem.register(GroupActionTranscriptChatItemRepresentation.self, for: .groupAction)
        ChatItem.register(PluginChatItemRepresentation.self, for: .plugin)
        ChatItem.register(TextChatItemRepresentation.self, for: .text)
        ChatItem.register(AcknowledgmentChatItemRepresentation.self, for: .acknowledgment)
        ChatItem.register(AssociatedMessageItemRepresentation.self, for: .associated)
        ChatItem.register(Message.self, for: .message)
        ChatItem.register(StubChatItemRepresentation.self, for: .phantom)
        ChatItem.register(GroupTitleChangeItemRepresentation.self, for: .groupTitle)
        ChatItem.register(TypingChatItemRepresentation.self, for: .typing)
    }
}

func wrapChatItem(unknownItem raw: NSObject, withChatGroupID groupID: String) -> ChatItem? {
    let item: NSObject = raw
    
    if item is IMTranscriptChatItem || item is IMGroupTitleChangeItem || item is IMParticipantChangeItem || item is IMGroupTitleChangeChatItem || item is IMGroupActionItem {
        var chatItem: ChatItem? = nil
        
        switch (item) {
        case let item as IMDateChatItem:
            chatItem = ChatItem(type: .date, item: DateTranscriptChatItemRepresentation(item, chatGroupID: groupID))
        case let item as IMSenderChatItem:
            chatItem = ChatItem(type: .sender, item: SenderTranscriptChatItemRepresentation(item, chatGroupID: groupID))
        case let item as IMParticipantChangeItem:
            chatItem = ChatItem(type: .participantChange, item: ParticipantChangeTranscriptChatItemRepresentation(item, chatGroupID: groupID))
        case let item as IMParticipantChangeChatItem:
            chatItem = ChatItem(type: .participantChange, item: ParticipantChangeTranscriptChatItemRepresentation(item, chatGroupID: groupID))
        case let item as IMMessageStatusChatItem:
            chatItem = ChatItem(type: .status, item: StatusChatItemRepresentation(item, chatGroupID: groupID))
        case let item as IMGroupActionItem:
            chatItem = ChatItem(type: .groupAction, item: GroupActionTranscriptChatItemRepresentation(item, chatGroupID: groupID))
        case let item as IMGroupActionChatItem:
            chatItem = ChatItem(type: .groupAction, item: GroupActionTranscriptChatItemRepresentation(item, chatGroupID: groupID))
        case let item as IMGroupTitleChangeChatItem:
            chatItem = ChatItem(type: .groupTitle, item: GroupTitleChangeItemRepresentation(item, chatGroupID: groupID))
        case let item as IMGroupTitleChangeItem:
            chatItem = ChatItem(type: .groupTitle, item: GroupTitleChangeItemRepresentation(item, chatGroupID: groupID))
        case let item as IMTypingChatItem:
            chatItem = ChatItem(type: .typing, item: TypingChatItemRepresentation(item, chatGroupID: groupID))
        default:
            break
        }
        
        if let chatItem = chatItem {
            var imItem: IMItem!
            
            if let item = item as? IMTranscriptChatItem {
                imItem = item._item()
            } else if let item = item as? IMItem {
                imItem = item
            } else {
                fatalError("Got an unexpected IMItem in the transcript parser")
            }
            
            return ChatItem(type: .message, item: Message(imItem, transcriptRepresentation: chatItem, chatGroupID: groupID))
        }
    }
    
    switch (item) {
    case let item as IMAttachmentMessagePartChatItem:
        return ChatItem(type: .attachment, item: AttachmentChatItemRepresentation(item, chatGroupID: groupID))
    case let item as IMTranscriptPluginChatItem:
        return ChatItem(type: .plugin, item: PluginChatItemRepresentation(item, chatGroupID: groupID))
    case let item as IMTextMessagePartChatItem:
        return ChatItem(type: .text, item: TextChatItemRepresentation(item, chatGroupID: groupID))
    case let item as IMMessageAcknowledgmentChatItem:
        return ChatItem(type: .acknowledgment, item: AcknowledgmentChatItemRepresentation(item, chatGroupID: groupID))
    case let item as IMAssociatedMessageItem:
        return ChatItem(type: .message, item: Message(item, chatGroupID: groupID))
    case let item as IMMessage:
        return ChatItem(type: .message, item: Message(item, chatGroupID: groupID))
    case let item as IMMessageItem:
        return ChatItem(type: .message, item: Message(item, chatGroupID: groupID))
    default:
        print("Discarding unknown ChatItem '\(item)'")
        return ChatItem(type: .phantom, item: StubChatItemRepresentation(item, chatGroupID: groupID))
    }
}

func parseArrayOf(chatItems: [NSObject], withGroupID groupID: String) -> [ChatItem] {
     let messages: [ChatItem?] = chatItems.map { item in
         wrapChatItem(unknownItem: item, withChatGroupID: groupID)
     }

     return messages.filter { $0 != nil } as! [ChatItem]
 }

struct StubChatItemRepresentation: ChatItemRepresentation, Content {
    init(_ item: NSObject, chatGroupID chat: String?) {
        guid = NSString.stringGUID()
        fromMe = false
        time = 0
        className = NSStringFromClass(type(of: item))
    }
    
    var guid: String?
    var chatGroupID: String?
    var fromMe: Bool?
    var time: Double?
    var className: String
}
