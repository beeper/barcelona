//
//  SendMessageCommand.swift
//  grapple
//
//  Created by Eric Rabil on 7/26/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import SwiftCLI
import Barcelona
import IMCore
import BarcelonaMautrixIPC

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
        if isID {
            guard let chat = Chat.resolve(withIdentifier: destination) else {
                fatalError("Unknown chat with identifier \(destination)")
            }
            
            return chat
        }
        
        if let self = self as? ChatCommandGUIDSupporting, self.isGUID {
            guard let chat = IMChatRegistry.shared.existingChat(withGUID: destination) else {
                let components = destination.split(separator: ";")
                if components.count == 3 {
                    let service = components[0]
                    let group = components[1]
                    let identifier = components[2]
                    if group == "-" {
                        if let service = IMServiceStyle(rawValue: String(service))?.service, let account = IMAccountController.shared.bestAccount(forService: service) {
                            return Chat(IMChatRegistry.shared.chat(for: account.imHandle(withID: String(identifier))))
                        }
                    }
                }
                fatalError("unknown chat with GUID \(destination)")
            }
            
            return Chat(chat)
        }
        
        return Chat.chat(withHandleIDs: destination.split(separator: ",").map(String.init), service: _sms ? .SMS : nil)
    }
}

private let encoder = JSONEncoder()
private extension Encodable {
    var json: Data {
        try! encoder.encode(self)
    }
    
    var jsonString: String {
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
                BLLoadChatItems(withChatIdentifier: chat, onServices: [.iMessage, .SMS], afterDate: nil, beforeDate: nil, afterGUID: nil, beforeGUID: nil, limit: limit ?? 100).then(
                    onlyIDs ? { chatItems in
                        print(chatItems.map { MessageIdentifier(messageID: $0.id, chatID: $0.chatID) }.jsonString)
                    } : { chatItems in
                        print(chatItems.map { $0.eraseToAnyChatItem() }.jsonString)
                    }
                ).observeAlways { _ in
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
                BLLoadChatItems(withGUIDs: ids).then { items in
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
                let metadata = try JSONDecoder().decode(RichLinkMetadata.self, from: Data(contentsOf: URL(fileURLWithPath: jsonPath)))
                let message = ERCreateBlankRichLinkMessage(text)
                try message.provideLinkMetadata(metadata)
                monitor = BLMediaMessageMonitor(messageID: message.id, transferGUIDs: message._imMessageItem?.fileTransferGUIDs ?? []) { success, error, cancel in
                    print(success, error?.description, cancel)
                    self.monitor = nil
                    exit(0)
                }
                chat.imChat.send(message)
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
            
            static func ERSendIMessage(to: String, text: String, _ sms: Bool) throws -> Message {
                let chat = Chat.directMessage(withHandleID: to, service: sms ? .SMS : .iMessage)
                let message = try chat.send(message: CreateMessage(parts: [.init(type: .text, details: text)]))
                return message
            }
            
            var text: String {
                message.joined(separator: " ")
            }
            
            func execute() throws {
                IMChatRegistry.shared._postMessageSentNotifications = true
                
                var message: Message! = nil
                
                NotificationCenter.default.addObserver(forName: .IMChatRegistryMessageSent, object: nil, queue: nil) { notification in
                    guard let sentMessage = notification.userInfo?["__kIMChatRegistryMessageSentMessageKey"] as? IMMessage else {
                        return
                    }
                    
                    guard message?.id == sentMessage.id else {
                        return
                    }
                    
                    print(sentMessage.debugDescription)
                    
                    if self.autoReply {
                        if #available(macOS 11.0, *) {
                            let create = CreateMessage(subject: nil, parts: [.init(type: .text, details: "asdf")], isAudioMessage: nil, flags: nil, ballonBundleID: nil, payloadData: nil, expressiveSendStyleID: nil, threadIdentifier: sentMessage.threadIdentifier(), replyToPart: 0, replyToGUID: sentMessage.guid)
                            let chat = Chat.directMessage(withHandleID: self.destination, service: self.sms ? .SMS : .iMessage)
                            try! chat.send(message: create)
                        } else {
                            // Fallback on earlier versions
                        }
                    } else {
                        exit(0)
                    }
                    
                    exit(0)
                }
                
                if force {
                    message = try Self.ERSendIMessage(to: destination, text: text, sms)
                } else {
                    if pingEveryone {
                        message = try chat.pingEveryone(text: text)
                    } else {
                        message = try chat.send(message: CreateMessage(parts: [MessagePart(type: .text, details: text)]))
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
                
                var message: Message! = nil
                
                NotificationCenter.default.addObserver(forName: .IMChatRegistryMessageSent, object: nil, queue: nil) { notification in
                    guard let sentMessage = notification.userInfo?["__kIMChatRegistryMessageSentMessageKey"] as? IMMessage else {
                        return
                    }
                    
                    guard message?.id == sentMessage.id else {
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
                message = try chat.tapback(.init(item: parts[part].id, message: targetMessage.id, type: Int(type.rawValue)))
            }
        }
        
        class Transfer: BarcelonaCommand, ChatCommandLike, ChatSMSForcingCapable {
            let name = "transfer"
            
            @Param var destination: String
            
            @Flag("-i", "--id", description: "treat the destination as a chat ID")
            var isID: Bool
            
            @Flag("-s") var sms: Bool
            
            @CollectedParam var transfers: [String]
            var monitor: BLMediaMessageMonitor?
            
            func execute() throws {
                var fileTransfers: [IMFileTransfer] = []
                for transfer in transfers {
                    let url = URL(fileURLWithPath: transfer)
                    fileTransfers.append(CBInitializeFileTransfer(filename: url.lastPathComponent, path: url))
                }
                let creation = CreateMessage(parts: fileTransfers.map {
                    .init(type: .attachment, details: $0.guid)
                })
                var messageID: String = ""
                monitor = BLMediaMessageMonitor(messageID: messageID, transferGUIDs: fileTransfers.map(\.guid)) { success, error, cancel in
                    print(success, error, cancel)
                    exit(0)
                }
                let message = try chat.sendReturningRaw(message: creation)
                messageID = message.id
            }
        }
        
        var children: [Routable] = [Text(), Tapback(), Transfer(), Link()]
    }
    
    var children: [Routable] = [Send(), Get()]
}

class SendMessageCommand: BarcelonaCommand {
    let name = "send-message"
    let shortDescription = "send a textual message to a chat with either a comma-delimited set of recipients or a chat identifier"
    
    @Param var destination: String
    @Param var message: String
    
    @Flag("-i", "--id", description: "treat the destination as a chat ID")
    var isID: Bool
    
    var chat: Chat {
        if isID {
            guard let chat = Chat.resolve(withIdentifier: destination) else {
                fatalError("Unknown chat with identifier \(destination)")
            }
            
            return chat
        }
        
        return Chat.chat(withHandleIDs: destination.split(separator: ",").map(String.init))
    }
    
    func execute() throws {
        IMChatRegistry.shared._postMessageSentNotifications = true
        
        var message: Message! = nil
        
        NotificationCenter.default.addObserver(forName: .IMChatRegistryMessageSent, object: nil, queue: nil) { notification in
            guard let sentMessage = notification.userInfo?["__kIMChatRegistryMessageSentMessageKey"] as? IMMessage else {
                return
            }
            
            guard message?.id == sentMessage.id else {
                return
            }
            
            print(sentMessage.debugDescription)
            
            exit(0)
        }
        
        message = try chat.send(message: CreateMessage(parts: [MessagePart(type: .text, details: self.message)]))
    }
}
