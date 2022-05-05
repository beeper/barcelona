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
        
        class Text: BarcelonaCommand, ChatCommandLike, ChatSMSForcingCapable {
            let name = "text"
            
            @Param var destination: String
            @CollectedParam var message: [String]
            
            @Flag("-i", "--id", description: "treat the destination as a chat ID")
            var isID: Bool
            
            @Flag("-e", "--everyone", description: "ping everyone because you crave attention")
            var pingEveryone: Bool
            
            @Flag("-s") var sms: Bool
            
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
        
        var children: [Routable] = [Text(), Tapback()]
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
