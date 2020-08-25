//
//  ChatItemV2.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 8/17/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import Vapor

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
