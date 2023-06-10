//
//  IPCCommand.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 5/24/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Barcelona
import BarcelonaFoundation
import Foundation
import Logging
import Sentry

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
    case get_messages_after(GetMessagesAfterCommand)
    case get_recent_messages(GetRecentMessagesCommand)
    case message(BLMessage)
    case read_receipt(BLReadReceipt)
    case typing(BLTypingNotification)
    case chat(BLChat)
    case send_message_status(BLMessageStatus)
    case error(ErrorCommand)
    case log(LogCommand)
    case response(IPCResponse) /* bmi-no-decode */
    case bridge_status(BridgeStatusCommand)
    case resolve_identifier(ResolveIdentifierCommand)
    case prepare_dm(PrepareDMCommand)
    case prepare_group_chat(PrepareGroupChatCommand)
    case ping
    case pre_startup_sync
    case unknown

    #if DEBUG
    var runnable: Runnable? {
        switch self {
        case .send_message(let run as Runnable),
                .send_media(let run as Runnable),
                .send_tapback(let run as Runnable),
                .send_read_receipt(let run as Runnable),
                .set_typing(let run as Runnable),
                .get_chats(let run as Runnable),
                .get_chat(let run as Runnable),
                .get_chat_avatar(let run as Runnable),
                .get_messages_after(let run as Runnable),
                .get_recent_messages(let run as Runnable),
                .resolve_identifier(let run as Runnable),
                .prepare_dm(let run as Runnable),
                .prepare_group_chat(let run as Runnable):
            return run
        case .message, .read_receipt, .typing, .chat, .send_message_status, .error, .log, .response, .bridge_status, .ping, .pre_startup_sync, .unknown:
            return nil
        }
    }

    func runDummy() async {
        guard let runnable else {
            return
        }

        let socket = UnixSocketMautrixIPCChannel("/dev/null")
        let ipc = MautrixIPCChannel(inputHandle: socket, outputHandle: socket)
        let payload = IPCPayload(command: self)
        await runnable.run(payload: payload, ipcChannel: ipc)
    }
    #endif // DEBUG
}

private let log = Logger(label: "IPCPayload")

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
            log.debug(
                "Reply issued for a command that had no ID. Inbound name: \(self.command.name.rawValue) Outbound name: \(self.command.name.rawValue)",
                source: "Mautrix"
            )
            let breadcrumb = Breadcrumb(level: .debug, category: "IPC")
            breadcrumb.message = "Reply issued for a command that had no ID"
            breadcrumb.data = [
                "inbound_name": self.command.name.rawValue,
                "outbound": command.name.rawValue,
            ]
            SentrySDK.addBreadcrumb(breadcrumb)
            return
        }

        ipcChannel.writePayload(IPCPayload(id: id, command: command))
    }

    public func reply(withResponse response: IPCResponse, ipcChannel: MautrixIPCChannel) {
        let breadcrumb = Breadcrumb(level: .info, category: "IPC")
        breadcrumb.message = "reply"
        breadcrumb.data = [
            "id": id ?? -1
        ]
        SentrySDK.addBreadcrumb(breadcrumb)
        reply(withCommand: .response(response), ipcChannel: ipcChannel)
    }

    public func fail(code: String, message: String, ipcChannel: MautrixIPCChannel) {
        let breadcrumb = Breadcrumb(level: .error, category: "IPC")
        breadcrumb.message = "fail"
        breadcrumb.data = [
            "id": id ?? -1,
            "code": code,
            "message": message,
        ]
        reply(withCommand: .error(.init(code: code, message: message)), ipcChannel: ipcChannel)
    }

    public func fail(strategy: ErrorStrategy, ipcChannel: MautrixIPCChannel) {
        let breadcrumb = Breadcrumb(level: .error, category: "IPC")
        breadcrumb.message = "fail"
        breadcrumb.data = [
            "id": id ?? -1,
            "strategy": strategy,
        ]
        reply(withCommand: strategy.asCommand, ipcChannel: ipcChannel)
    }
}
