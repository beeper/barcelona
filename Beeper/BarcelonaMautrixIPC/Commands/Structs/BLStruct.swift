//
//  BLStruct.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 5/24/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation

/// Need to update the enums codable data? Paste the cases at the top into BLStruct.codegen.js and then paste the output of that below the CodingKeys declaration
public enum BLStruct: Codable {
    case message(BLMessage)
    case messageStatus(BLMessageStatus)
    case partialMessage(BLPartialMessage)
    case attachment(BLAttachment)
    case associatedMessage(BLAssociatedMessage)
    case readReceipt(BLReadReceipt)
    case typing(BLTypingNotification)
    case chat(BLChat)

    private enum CodingKeys: CodingKey, CaseIterable {
        case type
    }
    
    private enum BLStructName: String, Codable {
        case message
        case messageStatus
        case partialMessage
        case attachment
        case associatedMessage
        case readReceipt
        case typing
        case chat
    }

    private var structName: BLStructName {
        switch self {
        case .message(_): return .message
        case .messageStatus(_): return .messageStatus
        case .partialMessage(_): return .partialMessage
        case .attachment(_): return .attachment
        case .associatedMessage(_): return .associatedMessage
        case .readReceipt(_): return .readReceipt
        case .typing(_): return .typing
        case .chat(_): return .chat
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
            
        try container.encode(structName, forKey: .type)
        
        switch self {
        case .message(let object):
            try object.encode(to: encoder)
        case .messageStatus(let object):
            try object.encode(to: encoder)
        case .partialMessage(let object):
            try object.encode(to: encoder)
        case .attachment(let object):
            try object.encode(to: encoder)
        case .associatedMessage(let object):
            try object.encode(to: encoder)
        case .readReceipt(let object):
            try object.encode(to: encoder)
        case .typing(let object):
            try object.encode(to: encoder)
        case .chat(let object):
            try object.encode(to: encoder)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
            
        let objectType = try container.decode(BLStructName.self, forKey: .type)
        
        switch objectType {
        case .message:
            self = .message(try BLMessage(from: decoder))
        case .messageStatus:
            self = .messageStatus(try BLMessageStatus(from: decoder))
        case .partialMessage:
            self = .partialMessage(try BLPartialMessage(from: decoder))
        case .attachment:
            self = .attachment(try BLAttachment(from: decoder))
        case .associatedMessage:
            self = .associatedMessage(try BLAssociatedMessage(from: decoder))
        case .readReceipt:
            self = .readReceipt(try BLReadReceipt(from: decoder))
        case .typing:
            self = .typing(try BLTypingNotification(from: decoder))
        case .chat:
            self = .chat(try BLChat(from: decoder))
        }
    }
}
