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
import BarcelonaMautrixIPC

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

    @Flag("--force-available")
    var overwriteAvailability: Bool

    private func sendMessage() async {
        let chat = await getIMChatForChatGuid(self.chatGuid)
        log.info("Got chat \(String(describing: chat))")
        guard let chat else {
            log.error("No chat with that guid found")
            exit(1)
        }

        if overwriteAvailability {
            log.info("Forcing any IDS lookups to resolve to \"available\"")
            IDSResolver.overwrittenStatuses[chat.chatIdentifier] = 1
        }

        let messageCreation = CreateMessage(parts: [
            .init(type: .text, details: self.message ?? "Test Message")
        ])

        log.info("Message send task starting")
        let msg = try! await Chat(chat).sendReturningRaw(message: messageCreation)

        log.info("Message sent: \(msg)\nAwaiting statuses...")

        CBDaemonListener.shared.messageStatusPipeline.retainingSink { comp in
            // I don't think we'll ever get a completion for this pipeline. if we do, just quit
            log.info(":( messageStatusPipeline gave up on us: (\(comp))")
            exit(1)
        } receiveValue: { status in
            guard status.messageID == msg.id else {
                return
            }

            switch status.type {
            case .sent:
                log.info("Message was sent!")
                if chat.account.service?.id != .iMessage || chat.isGroupChat {
                    log.info("Message was sent to chat where there are no delivered statuses; exiting")
                    exit(0)
                }
            case .delivered:
                log.info("Message was delivered!! woohoo!!")
                exit(0)
            case .notDelivered:
                log.info(":( Message was not delivered: \(status.message.errorCode)")
                exit(0)
            case .downgraded:
                log.info("Uhhhh Message was downgraded somehow??: \(status.message.errorCode)")
            default:
                // don't care about anything else
                break
            }
        }
    }

    func execute() throws {
        log.info("SendMessageCLICommand")

        let listener = SendMessageIMDaemonListener()

        let controller = IMDaemonController.sharedInstance()
        controller.listener.addHandler(listener)

        // Set up a pipeline to send the message once we've finished loading
        listener.readySubject.retainingSink { _ in } receiveValue: {
            log.info("Chats are loaded!")
            _Concurrency.Task {
                await self.sendMessage()
            }
        }

        BarcelonaMautrix.run("/dev/null")
    }
}
