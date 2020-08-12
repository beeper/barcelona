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
    var chatGUID: String? { get set }
    var fromMe: Bool? { get set }
    var time: Double? { get set }
}

extension ChatItemRepresentation {
    internal mutating func load(item: IMItem, chatGUID chat: String?) {
        guid = item.guid
        chatGUID = chat
        fromMe = item.isFromMe
        time = (item.time?.timeIntervalSince1970 ?? 0) * 1000
    }
    
    internal mutating func load(item: IMTranscriptChatItem, chatGUID chat: String?) {
        
        guid = item.guid
        chatGUID = chat
        fromMe = item.isFromMe
        time = ((item.transcriptDate ?? item._timeAdded())?.timeIntervalSince1970 ?? item._item()?.time?.timeIntervalSince1970 ?? 0) * 1000
    }
}

struct BulkChatItemRepresentation: Content {
    var items: [ChatItem]
}

struct ChatItem: Content {
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

    init(from decoder: Decoder) throws {
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

    func encode(to encoder: Encoder) throws {
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
        ChatItem.register(MessageRepresentation.self, for: .message)
        ChatItem.register(StubChatItemRepresentation.self, for: .phantom)
        ChatItem.register(GroupTitleChangeItemRepresentation.self, for: .groupTitle)
    }
}

func wrapChatItem(unknownItem raw: NSObject, withChatGUID guid: String) -> ChatItem? {
    var item: NSObject = raw
    
    if item is IMTranscriptChatItem || item is IMGroupTitleChangeItem || item is IMParticipantChangeItem || item is IMGroupTitleChangeChatItem || item is IMGroupActionItem {
        var chatItem: ChatItem? = nil
        
        switch (item) {
        case let item as IMDateChatItem:
            chatItem = ChatItem(type: .date, item: DateTranscriptChatItemRepresentation(item, chatGUID: guid))
        case let item as IMSenderChatItem:
            chatItem = ChatItem(type: .sender, item: SenderTranscriptChatItemRepresentation(item, chatGUID: guid))
        case let item as IMParticipantChangeItem:
            chatItem = ChatItem(type: .participantChange, item: ParticipantChangeTranscriptChatItemRepresentation(item, chatGUID: guid))
        case let item as IMParticipantChangeChatItem:
            chatItem = ChatItem(type: .participantChange, item: ParticipantChangeTranscriptChatItemRepresentation(item, chatGUID: guid))
        case let item as IMMessageStatusChatItem:
            chatItem = ChatItem(type: .status, item: StatusChatItemRepresentation(item, chatGUID: guid))
        case let item as IMGroupActionItem:
            chatItem = ChatItem(type: .groupAction, item: GroupActionTranscriptChatItemRepresentation(item, chatGUID: guid))
        case let item as IMGroupActionChatItem:
            chatItem = ChatItem(type: .groupAction, item: GroupActionTranscriptChatItemRepresentation(item, chatGUID: guid))
        case let item as IMGroupTitleChangeChatItem:
            chatItem = ChatItem(type: .groupTitle, item: GroupTitleChangeItemRepresentation(item, chatGUID: guid))
        case let item as IMGroupTitleChangeItem:
            chatItem = ChatItem(type: .groupTitle, item: GroupTitleChangeItemRepresentation(item, chatGUID: guid))
        case let item as IMTypingChatItem:
            return nil
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
            
            return ChatItem(type: .message, item: MessageRepresentation(imItem, transcriptRepresentation: chatItem, chatGUID: guid))
        }
    }
    
    switch (item) {
    case let item as IMAttachmentMessagePartChatItem:
        return ChatItem(type: .attachment, item: AttachmentChatItemRepresentation(item, chatGUID: guid))
    case let item as IMTranscriptPluginChatItem:
        return ChatItem(type: .plugin, item: PluginChatItemRepresentation(item, chatGUID: guid))
    case let item as IMTextMessagePartChatItem:
        return ChatItem(type: .text, item: TextChatItemRepresentation(item, chatGUID: guid))
    case let item as IMMessageAcknowledgmentChatItem:
        return ChatItem(type: .acknowledgment, item: AcknowledgmentChatItemRepresentation(item, chatGUID: guid))
    case let item as IMAssociatedMessageItem:
        return ChatItem(type: .message, item: MessageRepresentation(item, chatGUID: guid))
    case let item as IMMessage:
        return ChatItem(type: .message, item: MessageRepresentation(item, chatGUID: guid))
    case let item as IMMessageItem:
        return ChatItem(type: .message, item: MessageRepresentation(item, chatGUID: guid))
    default:
        print("Discarding unknown ChatItem '\(item.className)'")
        return ChatItem(type: .phantom, item: StubChatItemRepresentation(item, chatGUID: guid))
    }
}

func parseArrayOf(chatItems: [NSObject], withGUID guid: String) -> [ChatItem] {
     let messages: [ChatItem?] = chatItems.map { item in
         wrapChatItem(unknownItem: item, withChatGUID: guid)
     }

     return messages.filter { $0 != nil } as! [ChatItem]
 }

struct StubChatItemRepresentation: ChatItemRepresentation, Content {
    init(_ item: NSObject, chatGUID chat: String?) {
        guid = NSString.stringGUID() as! String
        fromMe = false
        time = 0
        className = item.className
    }
    
    var guid: String?
    var chatGUID: String?
    var fromMe: Bool?
    var time: Double?
    var className: String
}
