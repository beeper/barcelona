//
//  IPCCommand.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 5/24/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import BarcelonaFoundation
import Barcelona

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
public enum IPCCommand {
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
    case response(IPCResponse) /* bmi-no-decode */
    case bridge_status(BridgeStatusCommand)
    case resolve_identifier(ResolveIdentifierCommand)
    case prepare_dm(PrepareDMCommand)
    case contacts(GetContactListResponse)
    case ping
    case pre_startup_sync
    case get_contact_list
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
    
    public func reply(withCommand command: IPCCommand, ipcChannel: MautrixIPCChannel) {
        guard let id = id else {
            return CLDebug("Mautrix", "Reply issued for a command that had no ID. Inbound name: %@ Outbound name: %@", self.command.name.rawValue, self.command.name.rawValue)
        }
        
        ipcChannel.writePayload(IPCPayload(id: id, command: command))
    }
    
    public func reply(withResponse response: IPCResponse, ipcChannel: MautrixIPCChannel) {
        reply(withCommand: .response(response), ipcChannel: ipcChannel)
    }
    
    public func fail(code: String, message: String, ipcChannel: MautrixIPCChannel) {
        reply(withCommand: .error(.init(code: code, message: message)), ipcChannel: ipcChannel)
    }
    
    public func fail(strategy: ErrorStrategy, ipcChannel: MautrixIPCChannel) {
        reply(withCommand: strategy.asCommand, ipcChannel: ipcChannel)
    }
}
