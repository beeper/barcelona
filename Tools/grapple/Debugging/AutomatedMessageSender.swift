//
//  AutomatedMessageSender.swift
//  grapple
//
//  Created by Eric Rabil on 10/27/21.
//

import Barcelona
import Foundation
import Logging

struct BlockScheduler {
    var block: () -> Void
    var workItem: DispatchWorkItem?
    var queue: DispatchQueue = .main

    mutating func cancel() {
        workItem?.cancel()
        workItem = nil
    }

    mutating func schedule(milliseconds: Int) {
        cancel()

        var item: DispatchWorkItem?
        let block = block
        item = DispatchWorkItem {
            guard item!.isCancelled == false else {
                return
            }

            block()
        }
        workItem = item
        queue.asyncAfter(deadline: .now().advanced(by: .milliseconds(milliseconds)), execute: item!)
    }
}

private let encoder: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    return encoder
}()

extension Encodable {
    func printOut() {
        print(String(decoding: try! encoder.encode(self), as: UTF8.self))
    }
}

class AutomatedMessageSender: GrappleDebugger {
    static let shared = AutomatedMessageSender()

    struct Configuration: Codable {
        // Automated tapbacks
        struct TapbackConfiguration: Codable {
            var interval: Int = 2  // every two messages, tapback
            var type: Int = 2000  // type of tapback to send
        }

        var chat: String = "info@orders.apple.com"  // chat ID to send to
        var messages: [String] = ["a", "b", "c"]  // will send these messages in a loop
        var delay: Int = 1000  // number of milliseconds to wait between messages, minimum of 250ms
        var count: Int = -1  // number of messages to send, sub-zero for infinite
        var waitForDelivery: Bool = false  // whether to wait for delivery before scheduling next
        var trackNonAutomated: Bool = false  // whether to track messages fromMe, but not sent by automated message sender
        var tapbacks: TapbackConfiguration?

        var sanitizedDelay: Int {
            if count < 0 || count > 100 {
                return max(250, delay)
            } else {
                return max(1, delay)
            }
        }

        func resolvedChat() async -> Chat {
            await Chat.chat(withHandleIDs: chat.split(separator: ",").map(String.init), service: .iMessage)
        }

        func message(atIndex index: Int) -> String {
            guard messages.indices.contains(index) else {
                return "Hello!"
            }

            return messages[index]
        }
    }

    let log = Logger(label: "Sender")

    var configuration = Configuration()
    lazy var scheduler = BlockScheduler(block: sendNext)

    var statusPipeline: CBPipeline<Void>?
    var nonAutomatedPipeline: CBPipeline<Void>?

    var statusChanges: [String: [(timestamp: Double, type: CBMessageStatusType)]] = [:]
    var sentMessages: [String: (timestamp: Double, text: String)] = [:]
    var sentTapbacks: [String] = []
    var pendingDeliveries: [String: () -> Void] = [:]

    var counter = 0 {
        didSet {
            guard configuration.count > 0 else {
                return
            }

            if counter >= configuration.count {
                scheduler.block = {}
            }
        }
    }

    var position = 0 {
        didSet {
            if position >= configuration.messages.count {
                position = 0
            }
        }
    }

    func start() {
        statusPipeline = CBDaemonListener.shared.messageStatusPipeline.pipe(note(statusChange:))
        scheduler.block = sendNext

        if configuration.trackNonAutomated {
            nonAutomatedPipeline = CBDaemonListener.shared.messagePipeline.pipe { message in
                if message.fromMe && !self.sentMessages.keys.contains(message.id) {
                    self.log.warning("Got an untracked message fromMe:")
                    message.printOut()
                }
            }
        }

        sendNext()
    }

    func stop() {
        pendingDeliveries = [:]
        scheduler.cancel()

        statusPipeline?.cancel()
        statusPipeline = nil

        nonAutomatedPipeline?.cancel()
        nonAutomatedPipeline = nil
    }

    func printReport() {
        log.info("\(self.sentMessages.count) messages were sent")

        for (messageID, messageData) in sentMessages {
            guard let statusChanges = statusChanges[messageID] else {
                log.warning("[\(messageData.timestamp)] [\(messageID)] no statuses! text=\(messageData.text)")
                continue
            }

            let stringifiedStatusChanges =
                statusChanges.map { timestamp, type in
                    "(\(timestamp), \(type))"
                }
                .joined(separator: " -> ")

            log.info("[\(messageData.timestamp)] [\(messageID)] \(stringifiedStatusChanges) text=\(messageData.text)")
        }
    }

    func reset() {
        sentMessages = [:]
        statusChanges = [:]
    }

    func note(statusChange: CBMessageStatusChange) {
        guard sentMessages.keys.contains(statusChange.messageID) else {
            return
        }

        switch statusChange.type {
        case .delivered:
            if let tapbacks = configuration.tapbacks {
                if counter % tapbacks.interval == 1 {
                    Task {
                        do {
                            let message = try await configuration.resolvedChat().tapback(
                                .init(
                                    item: statusChange.message.chatItems.first!.id,
                                    message: statusChange.messageID,
                                    type: tapbacks.type
                                )
                            )
                            sentTapbacks.append(message.id)

                        } catch {
                            log.error(
                                "Failed to send tapback to \(statusChange.messageID): \((error as NSError).debugDescription)"
                            )
                        }
                    }
                }
            }

            fallthrough
        case .downgraded, .played, .read:
            pendingDeliveries.removeValue(forKey: statusChange.messageID)?()
        default:
            break
        }

        statusChanges[statusChange.messageID, default: []].append((statusChange.time, statusChange.type))
        log.info("Got status change \"\(statusChange.type.rawValue)\" for \(statusChange.messageID)")
    }

    func sendNext() {
        Task {
            let text = configuration.message(atIndex: position)

            do {
                let message = try await configuration.resolvedChat().send(message: .init(stringLiteral: text))
                sentMessages[message.id] = (message.time, text)

                position += 1
                counter += 1

                log.info("Initiated send for \(message.id) (text={ \(text) })")

                if configuration.waitForDelivery {
                    pendingDeliveries[message.id] = {
                        self.scheduler.schedule(milliseconds: self.configuration.delay)
                    }
                    return
                }
            } catch {
                log.error("Failed to send text{ \(text) }: \((error as NSError).debugDescription)")
            }

            scheduler.schedule(milliseconds: configuration.delay)
        }
    }
}

extension CreateMessage: ExpressibleByStringLiteral {
    public init(stringLiteral: String) {
        self = CreateMessage(parts: [MessagePart(type: .text, details: stringLiteral)])
    }
}
