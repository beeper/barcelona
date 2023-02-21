//
//  ReadReceiptTester.swift
//  grapple
//
//  Created by Eric Rabil on 10/27/21.
//

import Barcelona
import Foundation
import Logging

extension Message {
    var isRead: Bool {
        flags.contains(.read)
    }
}

class ReadReceiptTester: GrappleDebugger {
    static let shared = ReadReceiptTester()

    struct Configuration: Codable {
        var chat: String = "info@orders.apple.com"  // chat ID whose messages to mark read
        var delay: Int = 1000  // number of milliseconds to wait before marking message as read
    }

    var messagePipeline: CBPipeline<Void>? { didSet { oldValue?.cancel() } }
    var statusPipeline: CBPipeline<Void>? { didSet { oldValue?.cancel() } }

    let log = Logger(label: "ReadReceipts")

    var config = Configuration()

    func start() {
        messagePipeline = CBDaemonListener.shared.messagePipeline.pipe(receive(message:))
        statusPipeline = CBDaemonListener.shared.messageStatusPipeline.pipe(receive(statusChange:))
    }

    func stop() {
        messagePipeline = nil
        statusPipeline = nil
    }

    func printReport() {

    }

    func reset() {

    }

    func receive(message: Message) {
        guard message.chatID == config.chat else {
            return
        }

        guard !message.fromMe else {
            return
        }

        guard !message.isRead else {
            log.warning("received message \(message.id) but it is already read")
            message.printOut()
            return
        }

        log.info("marking \(message.id) as read in \(self.config.delay)ms")

        DispatchQueue.main.asyncAfter(deadline: .now().advanced(by: .milliseconds(config.delay))) {
            message.imChat.markMessage(asRead: BLLoadIMMessage(withGUID: message.id)!)
        }
    }

    func receive(statusChange: CBMessageStatusChange) {
        guard statusChange.chatID == config.chat else {
            return
        }

        if statusChange.message.isFromMe() && statusChange.type == .read {
            log.info("message \(statusChange.messageID) marked as read at \(statusChange.time)")
        }
    }
}
