//
//  SendMessageCLICommand.swift
//  barcelona-mautrix
//
//  Created by Brad Murray on 2023-04-07.
//

import Barcelona
import Combine
import Foundation
import IMCore
import Logging
import SwiftCLI

private let log = Logger(label: "SendMessageCLICommand")

class SendMessageIMDaemonListener: NSObject, IMDaemonListenerProtocol {
    let readySubject = PassthroughSubject<Void, Never>()

    func loadedChats(_ chats: [[AnyHashable: Any]]!) {
        log.info("loadedChats")
        readySubject.send()
    }
}

class SendMessageCLICommand: Command {
    let name = "send_message"

    @Param var chatGuid: String
    @Param var message: String?

    func execute() throws {
        log.info("SendMessageCLICommand")

        let listener = SendMessageIMDaemonListener()

        let controller = IMDaemonController.sharedInstance()
        controller.listener.addHandler(listener)

        log.info("Connecting to daemon...")
        controller.addListenerID("com.beeper.barcelona.send_message", capabilities: FZListenerCapabilities.defaults_)
        controller.blockUntilConnected()
        log.info("Connected to daemon.")

        // Set up a pipeline to send the message once we've finished loading
        let readyPipeline = listener.readySubject.sink {
            log.info("Chats are loaded!")

            let chat = IMChatRegistry.shared.existingChat(withGUID: self.chatGuid)
            log.info("Got chat \(String(describing: chat))")
            guard let chat else {
                log.error("No chat with that guid found")
                exit(1)
            }

            let messageCreation = CreateMessage(parts: [
                .init(type: .text, details: self.message ?? "Test Message")
            ])

            _Concurrency.Task {
                log.info("Message send task starting")
                let _ = try await chat.send(message: messageCreation)

                log.info("Message sent!")
                exit(0)
            }
        }

        log.info("Loading chats")
        if #available(macOS 12, *) {
            controller.loadAllChats()
        } else {
            controller.loadChats(withChatID: "all")
        }

        for account in IMAccountController.shared.accounts {
            // We want to make sure that nothing is prohibited us
            account.updateCapabilities(UInt64.max)
        }

        log.info("Starting the RunLoop")
        RunLoop.main.run()
    }
}
