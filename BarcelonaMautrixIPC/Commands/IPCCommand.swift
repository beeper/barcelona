//
//  IPCCommand.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 5/24/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation

public struct _IPCCommand: Codable {
    public var hello: Bool
}

public struct IPCError: Error {
    public let message: String?
    
    public init(_ message: String? = nil) {
        self.message = message
    }
    
    public var localizedDescription: String {
        self.message ?? "An unknown error occurred"
    }
}

/// Need to update the enums codable data? Paste the cases at the top into IPCCommand.codegen.js and then paste the output of that below the CodingKeys declaration
public enum IPCCommand: Codable {
    case send_message(SendMessageCommand)
    case send_media(SendMediaMessageCommand)
    case send_tapback(TapbackCommand)
    case send_read_receipt(SendReadReceiptCommand)
    case set_typing(SendTypingCommand)
    case get_chats(GetChatsCommand)
    case get_chat(GetGroupChatInfoCommand)
    case get_chat_avatar(GetGroupChatAvatarCommand)
    case get_contact(GetContactCommand)
    case get_messages_after(GetMessagesAfterCommand)
    case get_recent_messages(GetRecentMessagesCommand)
    case message(BLMessage)
    case read_receipt(BLReadReceipt)
    case typing(BLTypingNotification)
    case chat(BLChat)
    case contact(BLContact)
    case send_message_status(BLMessageStatus)
    case error(ErrorCommand)
    case log(LogCommand)
    case response(IPCResponse)
    
    private enum CodingKeys: CodingKey, CaseIterable {
        case command
        case data
    }
    
    public enum CommandName: String, Codable {
        case send_message
        case send_media
        case send_tapback
        case send_read_receipt
        case set_typing
        case get_chats
        case get_chat
        case get_chat_avatar
        case get_contact
        case get_messages_after
        case get_recent_messages
        case message
        case read_receipt
        case typing
        case chat
        case contact
        case send_message_status
        case error
        case log
        case response
    }

    public var name: CommandName {
        switch self {
        case .send_message(_): return .send_message
        case .send_media(_): return .send_media
        case .send_tapback(_): return .send_tapback
        case .send_read_receipt(_): return .send_read_receipt
        case .set_typing(_): return .set_typing
        case .get_chats(_): return .get_chats
        case .get_chat(_): return .get_chat
        case .get_chat_avatar(_): return .get_chat_avatar
        case .get_contact(_): return .get_contact
        case .get_messages_after(_): return .get_messages_after
        case .get_recent_messages(_): return .get_recent_messages
        case .message(_): return .message
        case .read_receipt(_): return .read_receipt
        case .typing(_): return .typing
        case .chat(_): return .chat
        case .contact(_): return .contact
        case .send_message_status(_): return .send_message_status
        case .error(_): return .error
        case .log(_): return .log
        case .response(_): return .response
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(name, forKey: .command)

        switch self {
        case .send_message(let command):
            try container.encode(command, forKey: .data)
        case .send_media(let command):
            try container.encode(command, forKey: .data)
        case .send_tapback(let command):
            try container.encode(command, forKey: .data)
        case .send_read_receipt(let command):
            try container.encode(command, forKey: .data)
        case .set_typing(let command):
            try container.encode(command, forKey: .data)
        case .get_chats(let command):
            try container.encode(command, forKey: .data)
        case .get_chat(let command):
            try container.encode(command, forKey: .data)
        case .get_chat_avatar(let command):
            try container.encode(command, forKey: .data)
        case .get_contact(let command):
            try container.encode(command, forKey: .data)
        case .get_messages_after(let command):
            try container.encode(command, forKey: .data)
        case .get_recent_messages(let command):
            try container.encode(command, forKey: .data)
        case .message(let command):
            try container.encode(command, forKey: .data)
        case .read_receipt(let command):
            try container.encode(command, forKey: .data)
        case .typing(let command):
            try container.encode(command, forKey: .data)
        case .chat(let command):
            try container.encode(command, forKey: .data)
        case .contact(let command):
            try container.encode(command, forKey: .data)
        case .send_message_status(let command):
            try container.encode(command, forKey: .data)
        case .error(let command):
            try container.encode(command, forKey: .data)
        case .log(let command):
            try container.encode(command, forKey: .data)
        case .response(let command):
            try container.encode(command, forKey: .data)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let command = try container.decode(CommandName.self, forKey: .command)

        switch command {
        case .send_message:
            self = .send_message(try container.decode(SendMessageCommand.self, forKey: .data))
        case .send_media:
            self = .send_media(try container.decode(SendMediaMessageCommand.self, forKey: .data))
        case .send_tapback:
            self = .send_tapback(try container.decode(TapbackCommand.self, forKey: .data))
        case .send_read_receipt:
            self = .send_read_receipt(try container.decode(SendReadReceiptCommand.self, forKey: .data))
        case .set_typing:
            self = .set_typing(try container.decode(SendTypingCommand.self, forKey: .data))
        case .get_chats:
            self = .get_chats(try container.decode(GetChatsCommand.self, forKey: .data))
        case .get_chat:
            self = .get_chat(try container.decode(GetGroupChatInfoCommand.self, forKey: .data))
        case .get_chat_avatar:
            self = .get_chat_avatar(try container.decode(GetGroupChatAvatarCommand.self, forKey: .data))
        case .get_contact:
            self = .get_contact(try container.decode(GetContactCommand.self, forKey: .data))
        case .get_messages_after:
            self = .get_messages_after(try container.decode(GetMessagesAfterCommand.self, forKey: .data))
        case .get_recent_messages:
            self = .get_recent_messages(try container.decode(GetRecentMessagesCommand.self, forKey: .data))
        case .message:
            self = .message(try container.decode(BLMessage.self, forKey: .data))
        case .read_receipt:
            self = .read_receipt(try container.decode(BLReadReceipt.self, forKey: .data))
        case .typing:
            self = .typing(try container.decode(BLTypingNotification.self, forKey: .data))
        case .chat:
            self = .chat(try container.decode(BLChat.self, forKey: .data))
        case .contact:
            self = .contact(try container.decode(BLContact.self, forKey: .data))
        case .send_message_status:
            self = .send_message_status(try container.decode(BLMessageStatus.self, forKey: .data))
        case .error:
            self = .error(try container.decode(ErrorCommand.self, forKey: .data))
        case .log:
            self = .log(try container.decode(LogCommand.self, forKey: .data))
        case .response:
            throw IPCError("Responses cannot be decoded until they have a type identifier")
        }
    }
}

public struct IPCPayload: Codable {
    public var command: IPCCommand
    public var id: Int?
    
    private enum CodingKeys: CodingKey, CaseIterable {
        case id
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        if command.name != .log, let id = id {
            try container.encode(id, forKey: .id)
        }
        
        try command.encode(to: encoder)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        command = try IPCCommand(from: decoder)
        let commandID = try? container.decode(Int.self, forKey: .id)
        
        id = commandID
    }
    
    public init(id: Int? = nil, command: IPCCommand) {
        self.id = id
        self.command = command
    }
    
    public func reply(withCommand command: IPCCommand) {
        guard let id = id else {
            return BLDebug("Reply issued for a command that had no ID. Inbound name: %@ Outbound name: %@", self.command.name.rawValue, self.command.name.rawValue)
        }
        
        BLWritePayload(IPCPayload(id: id, command: command))
    }
    
    public func fail(code: String, message: String) {
        reply(withCommand: .error(.init(code: code, message: message)))
    }
    
    public func fail(strategy: ErrorStrategy) {
        reply(withCommand: strategy.asCommand)
    }
}
