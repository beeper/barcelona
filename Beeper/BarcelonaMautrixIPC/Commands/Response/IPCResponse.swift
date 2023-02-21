//
//  IPCResponse.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 6/1/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import Logging

extension IPCPayload {
    public func respond(_ response: IPCResponse, ipcChannel: MautrixIPCChannel) {
        self.reply(withCommand: .response(response), ipcChannel: ipcChannel)
    }
}

public enum IPCResponse: Encodable {
    case chats_resolved([String])
    case chat_resolved(BLChat?)
    case messages([BLMessage])
    case chat_avatar(BLAttachment?)
    case message_receipt(BLPartialMessage)
    case guid(GUIDResponse)
    case arbitrary(any Codable)
    case ack
    case none

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .chats_resolved(let data):
            try container.encode(data)
        case .chat_resolved(let data):
            try container.encode(data)
        case .messages(let data):
            try container.encode(data)
        case .chat_avatar(let data):
            try container.encode(data)
        case .message_receipt(let data):
            try container.encode(data)
        case .arbitrary(let codable):
            try container.encode(codable)
        case .ack:
            try container.encodeNil()
        case .none:
            try container.encodeNil()
        case .guid(let data):
            try container.encode(data)
        }
    }
}
