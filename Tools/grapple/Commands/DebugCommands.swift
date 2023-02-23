//
//  DebugCommands.swift
//  grapple
//
//  Created by Eric Rabil on 7/26/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Barcelona
import BarcelonaMautrixIPC
import Foundation
import IMCore
import IMDPersistence
import IMSharedUtilities
import Logging
import SwiftCLI
import SwiftyTextTable

extension String {
    fileprivate init(debugDescribing value: Any) {
        if let debugConvertable = value as? CustomDebugStringConvertible {
            self.init(debugConvertable.debugDescription)
        } else {
            self.init(describing: value)
        }
    }
}

@_cdecl("_CSDBCheckResultWithStatement")
func _CSDBCheckResultWithStatement(
    _ a: UnsafeRawPointer,
    _ b: UnsafeRawPointer,
    _ c: UnsafeRawPointer,
    _ d: UnsafeRawPointer,
    _ e: UnsafeRawPointer
) {

}

extension Encodable {
    fileprivate var dump: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        do {
            return try String(decoding: encoder.encode(self), as: UTF8.self)
        } catch {
            if let description = (self as? CustomDebugStringConvertible)?.debugDescription {
                return description
            }

            return ""
        }
    }
}

class DebugCommands: CommandGroup {
    let name = "debug"
    let shortDescription = "commands useful when debugging barcelona"

    class ChatRegistry: Command {
        let name = "registry"

        func execute() throws {
            LoggingDrivers = [OSLogDriver.shared]
            try HookManager.shared.apply()
            DispatchQueue.main.async {
                _ = CBChatRegistry.shared
                _ = CBFileTransferCenter.shared
                let controller = IMDaemonController.sharedInstance()
                controller.addListenerID(BLListenerIdentifier, capabilities: FZListenerCapabilities.defaults_)
                controller.blockUntilConnected()
                controller.fetchNicknames()
            }
            RunLoop.main.run()
        }
    }

    class DebugEventsCommand: BarcelonaCommand {
        let name = "events"

        @Flag("--mautrix") var logAsMautrix: Bool
        @Flag("--transfers") var logTransferUpdates: Bool

        init() {
            //            LoggingDrivers = []
        }

        func execute() throws {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted

            func json<P: Encodable>(_ encodable: P) -> String {
                String(decoding: try! encoder.encode(encodable), as: UTF8.self)
            }

            if !LoggingDrivers.contains(where: { $0 is ConsoleDriver }) {
                LoggingDrivers.append(ConsoleDriver.shared)
            }

            if logTransferUpdates {
                func handleTransferNotification(_ notification: Notification) {
                    guard let transfer = notification.object as? IMFileTransfer else {
                        return
                    }
                    print(
                        ([
                            "name": notification.name,
                            "transfer": transfer,
                        ] as NSDictionary)
                        .prettyJSON
                    )
                    visited = Set()
                }

                NotificationCenter.default.addObserver(
                    forName: .IMFileTransferUpdated,
                    object: nil,
                    queue: nil,
                    using: handleTransferNotification
                )
                NotificationCenter.default.addObserver(
                    forName: .IMFileTransferCreated,
                    object: nil,
                    queue: nil,
                    using: handleTransferNotification
                )
            }

            let log = Logger(label: "DebugEventsCommand")

            CBDaemonListener.shared.aggregatePipeline.pipe { event in
                if self.logAsMautrix {
                    switch event {
                    case .message(let message):
                        log.info("\(json(BLMessage(message: message)))", metadata: nil, source: "BLEvents")
                        return
                    default:
                        break
                    }
                }

                log.info("\(json(event))", source: "BLEvents")
            }
        }
    }

    class IMDTest: BarcelonaCommand {
        let name = "imd"

        func execute() throws {
            _Concurrency.Task {
                guard let _chat = IMChatRegistry.shared.allChats.first else {
                    return
                }

                let chat = Chat(_chat)

                let msgs = try await chat.messages()
                print(msgs)
            }
        }
    }

    class AlwaysRead: BarcelonaCommand {
        let name = "always-read"

        @Flag("-e", "--enable-read-receipts", description: "forcibly enable sending read receipts for this chat")
        var enableReadReceipts: Bool
        @Flag("-s", "--sms", description: "Find chat on SMS service (will find on iMessage otherwise)") var sms: Bool
        @Param var chatID: String

        func execute() throws {
            if enableReadReceipts,
                let chat = IMChat.chat(withIdentifier: chatID, onService: sms ? .SMS : .iMessage, style: nil)
            {
                chat.userToggledReadReceiptSwitch(true)
                chat.markAllMessagesAsRead()
            }
            CBDaemonListener.shared.unreadCountPipeline.pipe { chatID, count in
                guard chatID == self.chatID else {
                    return
                }
                guard let chat = IMChat.chat(withIdentifier: chatID, onService: self.sms ? .SMS : .iMessage, style: nil)
                else {
                    return
                }
                chat.markAllMessagesAsRead()
            }
        }
    }

    class Pong: BarcelonaCommand {
        let name = "pong"

        @Param var chatID: String
        @Param var triggerText: String
        @Param var copyText: String

        func execute() throws {
            CBDaemonListener.shared.messagePipeline.pipe { message in
                if message.chatID == self.chatID, !message.fromMe,
                    message.items.contains(where: { ($0.item as? TextChatItem)?.text == self.triggerText })
                {
                    try! MessageCommand.Send.Text.ERSendIMessage(to: self.chatID, text: self.copyText, false)
                }
            }
        }
    }

    var children: [Routable] = [DebugEventsCommand(), IMDTest(), AlwaysRead(), Pong(), ChatRegistry()]
}
