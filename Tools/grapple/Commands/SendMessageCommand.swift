//
//  SendMessageCommand.swift
//  grapple
//
//  Created by Eric Rabil on 7/26/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Barcelona
import BarcelonaMautrixIPC
import Foundation
import IMCore
import IMSharedUtilities
import SwiftCLI

extension IMAssociatedMessageType: ConvertibleFromString {
    public init?(input: String) {
        guard let type = Int64(input).flatMap(IMAssociatedMessageType.init(rawValue:)) else {
            return nil
        }
        self = type
    }
}

protocol ChatCommandLike {
    var isID: Bool { get }
    var destination: String { get }
}

protocol ChatCommandGUIDSupporting {
    var isGUID: Bool { get }
}

protocol ChatSMSForcingCapable: ChatCommandLike {
    var sms: Bool { get }
}

extension ChatCommandLike {
    var _sms: Bool {
        if let cap = self as? ChatSMSForcingCapable {
            return cap.sms
        }
        return false
    }

    var chat: Chat {
        get async {
            if isID {
                if _sms {
                    guard let imChat = IMChat.chat(withIdentifier: destination, onService: .SMS, style: nil) else {
                        fatalError("Unknown chat with identifier \(destination)")
                    }

                    return await Chat(imChat)
                }

                return await Chat.firstChatRegardlessOfService(withId: destination)!
            }

            if let self = self as? ChatCommandGUIDSupporting, self.isGUID {
                guard let chat = IMChatRegistry.shared.existingChat(withGUID: destination) else {
                    let components = destination.split(separator: ";")
                    if components.count == 3 {
                        let service = components[0]
                        let group = components[1]
                        let identifier = components[2]
                        if group == "-" {
                            if let service = IMServiceStyle(rawValue: String(service))?.service,
                               let account = IMAccountController.shared.bestAccount(forService: service)
                            {
                                return await Chat(IMChatRegistry.shared.chat(for: account.imHandle(withID: String(identifier))))
                            }
                        }
                    }
                    fatalError("unknown chat with GUID \(destination)")
                }

                return await Chat(chat)
            }

            return await Chat.chat(
                withHandleIDs: destination.split(separator: ",").map(String.init),
                service: _sms ? .SMS : .iMessage
            )
        }
    }
}

private let encoder = JSONEncoder()
extension Encodable {
    fileprivate var json: Data {
        try! encoder.encode(self)
    }

    fileprivate var jsonString: String {
        String(decoding: json, as: UTF8.self)
    }
}

class MessageCommand: CommandGroup {
    let name = "message"
    let shortDescription = "do message things"

    class Get: CommandGroup {
        let name = "get"
        let shortDescription = "get messages"

        class RecentMessages: BarcelonaCommand {
            let name = "recents"

            @Param var chat: String
            @Key("-l", "--limit", description: "Max number of results to return, default 100") var limit: Int?
            @Flag("-i", "--id", description: "Only return the message and chat IDs") var onlyIDs: Bool

            private struct MessageIdentifier: Codable {
                var messageID: String
                var chatID: String
            }

            func execute() throws {
                _Concurrency.Task {
                    let chatItems = try await BLLoadChatItems(
                        withChats: [(chat, .iMessage), (chat, .SMS)],
                        afterDate: nil,
                        beforeDate: nil,
                        afterGUID: nil,
                        beforeGUID: nil,
                        limit: limit ?? 100
                    )

                    if onlyIDs {
                        print(chatItems.map { MessageIdentifier(messageID: $0.id, chatID: $0.chatID) }.jsonString)
                    } else {
                        print(chatItems.map { $0.eraseToAnyChatItem() }.jsonString)
                    }

                    exit(0)
                }
            }
        }

        class Exact: BarcelonaCommand {
            let name = "exact"

            @CollectedParam var ids: [String]

            var mautrix: Bool {
                ids.contains(where: { $0 == "-m" || $0 == "--mautrix" })
            }

            func execute() throws {
                _Concurrency.Task {
                    let items = try await BLLoadChatItems(withGUIDs: ids, service: .iMessage)

                    if self.mautrix {
                        print(items.compactMap { $0 as? Message }.map { BLMessage(message: $0) }.prettyJSON)
                    } else {
                        print(items.map { $0.eraseToAnyChatItem() }.prettyJSON)
                    }
                }
            }
        }

        var children: [Routable] = [RecentMessages(), Exact()]
    }

    class Send: CommandGroup {
        let name = "send"
        let shortDescription = "send messages"

        /// send ad-hoc link metadata
        class Link: BarcelonaCommand, ChatCommandLike, ChatSMSForcingCapable, ChatCommandGUIDSupporting {
            let name = "link"

            @Param var destination: String

            @Param var text: String
            @Param var jsonPath: String

            @Flag("-i", "--id", description: "treat the destination as a chat ID")
            var isID: Bool

            @Flag("-g", "--guid", description: "treat the destination as a chat GUID")
            var isGUID: Bool

            @Flag("-s") var sms: Bool
            @Flag("-f") var force: Bool

            var monitor: BLMediaMessageMonitor?

            func execute() throws {
                _Concurrency.Task {
                    let metadata = try! JSONDecoder()
                        .decode(RichLinkMetadata.self, from: Data(contentsOf: URL(fileURLWithPath: jsonPath)))

                    let message = ERCreateBlankRichLinkMessage(text, URL(string: "https://google.com")!)
                    let afterSend = try message.provideLinkMetadata(metadata)

                    monitor = BLMediaMessageMonitor(
                        messageID: message.id,
                        transferGUIDs: message._imMessageItem?.fileTransferGUIDs ?? []
                    ) { success, error, cancel in
                        print(success, error?.description as Any, cancel)
                        self.monitor = nil
                    }

                    await chat.imChat!.send(message)
                    afterSend()
                }
            }
        }

        class Text: BarcelonaCommand, ChatCommandLike, ChatSMSForcingCapable, ChatCommandGUIDSupporting {
            let name = "text"

            @Param var destination: String
            @CollectedParam var message: [String]

            @Flag("-e", "--everyone", description: "ping everyone because you crave attention")
            var pingEveryone: Bool

            @Flag("-i", "--id", description: "treat the destination as a chat ID")
            var isID: Bool

            @Flag("-g", "--guid", description: "treat the destination as a chat GUID")
            var isGUID: Bool

            @Flag("-s") var sms: Bool

            @Flag("-r") var autoReply: Bool

            @Flag("-f") var force: Bool

            @Key("--from") var from: String?

            static func ERSendIMessage(to: String, text: String, _ sms: Bool) async throws -> Message {
                let chat = await Chat.directMessage(withHandleID: to, service: sms ? .SMS : .iMessage)
                let message = try await chat.send(message: CreateMessage(parts: [.init(type: .text, details: text)]))
                return message
            }

            var text: String {
                message.joined(separator: " ")
            }

            func execute() throws {
                _Concurrency.Task {
                    IMChatRegistry.shared._postMessageSentNotifications = true

                    var message: Message! = nil

                    let msgIsSame: (IMMessage) -> Bool = {
                        message?.id == $0.id
                    }

                    NotificationCenter.default.addObserver(forName: .IMChatRegistryMessageSent, object: nil, queue: nil) {
                        notification in
                        guard
                            let sentMessage = notification.userInfo?["__kIMChatRegistryMessageSentMessageKey"] as? IMMessage
                        else {
                            return
                        }

                        guard msgIsSame(sentMessage) else {
                            return
                        }

                        print(sentMessage.debugDescription)

                        if self.autoReply {
                            if #available(macOS 11.0, *) {
                                let create = CreateMessage(
                                    subject: nil,
                                    parts: [.init(type: .text, details: "asdf")],
                                    isAudioMessage: nil,
                                    flags: nil,
                                    ballonBundleID: nil,
                                    payloadData: nil,
                                    expressiveSendStyleID: nil,
                                    threadIdentifier: sentMessage.threadIdentifier(),
                                    replyToPart: 0,
                                    replyToGUID: sentMessage.guid
                                )
                                _Concurrency.Task {
                                    let chat = await Chat.directMessage(
                                        withHandleID: self.destination,
                                        service: self.sms ? .SMS : .iMessage
                                    )
                                    _ = try! await chat.send(message: create)
                                }
                            } else {
                                // Fallback on earlier versions
                            }
                        } else {
                            exit(0)
                        }

                        exit(0)
                    }

                    if force {
                        message = try await Self.ERSendIMessage(to: destination, text: text, sms)
                    } else {
                        if pingEveryone {
                            message = try await chat.pingEveryone(text: text)
                        } else {
                            message = try await chat.send(
                                message: CreateMessage(parts: [MessagePart(type: .text, details: text)]),
                                from: from
                            )
                        }
                    }
                }
            }
        }

        class Tapback: BarcelonaCommand, ChatCommandLike {
            let name = "tapback"

            @Param var destination: String
            @Param var id: String
            @Param var part: Int
            @Param var type: IMAssociatedMessageType

            @Flag("-i", "--id", description: "treat the destination as a chat ID")
            var isID: Bool

            func execute() throws {
                IMChatRegistry.shared._postMessageSentNotifications = true

                _Concurrency.Task {
                    var message: Message! = nil

                    let idIsSame: (IMMessage) -> Bool = {
                        message?.id == $0.id
                    }

                    NotificationCenter.default.addObserver(forName: .IMChatRegistryMessageSent, object: nil, queue: nil) {
                        notification in
                        guard
                            let sentMessage = notification.userInfo?["__kIMChatRegistryMessageSentMessageKey"] as? IMMessage
                        else {
                            return
                        }

                        guard idIsSame(sentMessage) else {
                            return
                        }

                        print(sentMessage.debugDescription)

                        exit(0)
                    }

                    guard let targetMessage = BLLoadIMMessage(withGUID: id) else {
                        fatalError("Unknown message")
                    }
                    let parts = targetMessage._imMessageItem.chatItems
                    guard parts.indices.contains(part) else {
                        fatalError("Out of bounds. Message has these parts: \(parts.indices)")
                    }
                    message = try await chat.tapback(
                        .init(item: parts[part].id, message: targetMessage.id, type: Int(type.rawValue))
                    )
                }
            }
        }

        var children: [Routable] = [Text(), Tapback(), Transfer(), Link()]
    }

    var children: [Routable] = [Send(), Get()]
}

class SendMessageCommand: BarcelonaCommand {
    let name = "send-message"
    let shortDescription =
        "send a textual message to a chat with either a comma-delimited set of recipients or a chat identifier"

    @Param var destination: String
    @Param var message: String

    @Flag("-i", "--id", description: "treat the destination as a chat ID") var isID: Bool
    @Flag("-s", "--sms", description: "Send over SMS (will send on iMessage instead") var sms: Bool

    var chat: Chat {
        get async {
            if isID {
                guard let imChat = IMChat.chat(withIdentifier: destination, onService: sms ? .SMS : .iMessage, style: nil) else {
                    fatalError("Unknown chat with identifier \(destination)")
                }

                return await Chat(imChat)
            }

            return await Chat.chat(
                withHandleIDs: destination.split(separator: ",").map(String.init),
                service: sms ? .SMS : .iMessage
            )
        }
    }

    func execute() throws {
        IMChatRegistry.shared._postMessageSentNotifications = true

        _Concurrency.Task {
            var message: Message! = nil

            let idIsSame: (IMMessage) -> Bool = {
                message?.id == $0.id
            }

            NotificationCenter.default.addObserver(forName: .IMChatRegistryMessageSent, object: nil, queue: nil) {
                notification in
                guard let sentMessage = notification.userInfo?["__kIMChatRegistryMessageSentMessageKey"] as? IMMessage else {
                    return
                }

                guard idIsSame(sentMessage) else {
                    return
                }

                print(sentMessage.debugDescription)

                exit(0)
            }

            message = try await chat.send(message: CreateMessage(parts: [MessagePart(type: .text, details: self.message)]))
        }
    }
}
