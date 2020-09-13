//
//  Chat.swift
//  imcore-rest
//
//  Created by Eric Rabil on 7/23/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import NIO

enum ChatStyle: UInt8 {
    case group = 0x2b
    case single = 0x2d
}

class QueryFailedError: Error {
    init() {
        
    }
}

protocol BulkChatRepresentatable {
    var chats: [Chat] { get set }
}

struct BulkChatRepresentation: Codable, BulkChatRepresentatable {
    init(_ chats: [IMChat]) {
        self.chats = chats.map {
            Chat($0)
        }
    }
    
    init(_ chats: ArraySlice<IMChat>) {
        self.chats = chats.map {
            Chat($0)
        }
    }
    
    init(_ chats: [Chat]) {
        self.chats = chats
    }
    
    var chats: [Chat]
}

struct ChatIDRepresentation: Codable {
    var chat: String
}

enum MessagePartType: String, Codable {
    case text = "text"
    case attachment = "attachment"
}

struct MessagePart: Codable {
    var type: MessagePartType
    var details: String
}

struct CreateMessage: Codable {
    var subject: String?
    var parts: [MessagePart]
    var isAudioMessage: Bool?
    var flags: CLongLong?
    var ballonBundleID: String?
    var payloadData: String?
    var expressiveSendStyleID: String?
}

protocol MessageIdentifiable {
    var id: String { get set }
}

protocol ChatConfigurationRepresentable {
    var readReceipts: Bool { get set }
    var ignoreAlerts: Bool { get set }
}

struct ChatConfigurationRepresentation: Codable, ChatConfigurationRepresentable {
    var id: String
    var readReceipts: Bool
    var ignoreAlerts: Bool
}

struct DeleteMessage: Codable, MessageIdentifiable {
    var id: String
    var parts: [Int]?
}

extension MessageIdentifiable {
    func chat() -> EventLoopFuture<Chat?> {
        Chat.chat(forMessage: id)
    }
}

struct DeleteMessageRequest: Codable {
    var messages: [DeleteMessage]
}

private func flagsForCreation(_ creation: CreateMessage, transfers: [String]) -> FullFlagsFromMe {
    if let _ = creation.ballonBundleID { return .richLink }
    if let audio = creation.isAudioMessage { if audio { return .audioMessage } }
    if transfers.count > 0 || creation.parts.contains(where: { $0.type == .attachment }) { return .attachments }
    return .textOrPluginOrStickerOrImage
}

private extension String {
    func substring(trunactingFirst prefix: Int) -> Substring {
        self.suffix(from: self.index(startIndex, offsetBy: prefix))
    }
}

public struct Chat: Codable, ChatConfigurationRepresentable {
    init(_ backing: IMChat) {
        joinState = backing.joinState
        roomName = backing.roomName
        displayName = backing.displayName
        id = backing.id
        participants = backing.participantHandleIDs() ?? []
        lastAddressedHandleID = backing.lastAddressedHandleID
        unreadMessageCount = backing.unreadMessageCount
        messageFailureCount = backing.messageFailureCount
        service = backing.account?.service?.id
        lastMessage = backing.lastFinishedMessage?.description(forPurpose: 0x2, inChat: backing, senderDisplayName: backing.lastMessage?.sender._displayNameWithAbbreviation)
        lastMessageTime = (backing.lastFinishedMessage?.time.timeIntervalSince1970 ?? 0) * 1000
        style = backing.chatStyle
        readReceipts = backing.readReceipts
        ignoreAlerts = backing.ignoreAlerts
    }
    
    public static func chat(forMessage id: String) -> EventLoopFuture<Chat?> {
        IMChat.chat(forMessage: id).map {
            if let chat = $0 {
                return Chat(chat)
            } else {
                return nil
            }
        }
    }
    
    public var id: String
    var joinState: Int64
    var roomName: String?
    var displayName: String?
    var participants: [String]
    var lastAddressedHandleID: String?
    var unreadMessageCount: UInt64?
    var messageFailureCount: UInt64?
    var service: IMServiceStyle?
    var lastMessage: String?
    var lastMessageTime: Double
    var style: UInt8
    var readReceipts: Bool
    var ignoreAlerts: Bool
    
    var imChat: IMChat {
        IMChat.resolve(withIdentifier: id)!
    }
    
    func startTyping() {
        if imChat.localTypingMessageGUID == nil {
            imChat.setValue(NSString.stringGUID(), forKey: "_typingGUID")
            let message = IMMessage(sender: nil, time: nil, text: nil, fileTransferGUIDs: nil, flags: 0xc, error: nil, guid: imChat.localTypingMessageGUID, subject: nil)
            imChat._sendMessage(message, adjustingSender: true, shouldQueue: false)
        }
    }
    
    func stopTyping() {
        if let typingGUID = imChat.localTypingMessageGUID {
            imChat.setValue(nil, forKey: "_typingGUID")
            let message = IMMessage(sender: nil, time: nil, text: nil, fileTransferGUIDs: nil, flags: 0xd, error: nil, guid: typingGUID, subject: nil)
            imChat.sendMessage(message)
        }
    }
    
    func messages(before: String? = nil, limit: UInt64? = nil) -> EventLoopFuture<[ChatItem]> {
        if ERBarcelonaManager.isSimulation {
            let guids: [String] = imChat.chatItemRules._items().compactMap { item in
                if let chatItem = item as? IMChatItem {
                    return chatItem._item()?.guid
                } else if let item = item as? IMItem {
                    return item.guid
                }
                
                return nil
            }
            
            return IMMessage.messages(withGUIDs: guids, in: self.id, on: messageQuerySystem.next()).map { messages -> [ChatItem] in
                messages.sorted {
                    guard case .message(let message1) = $0, case .message(let message2) = $1 else {
                        return false
                    }
                    
                    return message1.time! > message2.time!
                }
            }
        }
        
        return DBReader.shared.rowIDs(forIdentifier: imChat.chatIdentifier).flatMap { ROWIDs -> EventLoopFuture<[String]> in
            let guidFetchTracker = ERTrack(log: .default, name: "Chat.swift:messages Loading newest guids for chat", format: "ChatID: %{public}s ROWIDs: %@", self.id, ROWIDs)
            
            return DBReader.shared.newestMessageGUIDs(inChatROWIDs: ROWIDs, beforeMessageGUID: before, limit: Int(limit ?? 100)).map {
                guidFetchTracker()
                return $0
            }
        }.flatMap { guids -> EventLoopFuture<[ChatItem]> in
            IMMessage.messages(withGUIDs: guids, in: self.id, on: messageQuerySystem.next())
        }.map { messages -> [ChatItem] in
            messages.sorted {
                guard case .message(let message1) = $0, case .message(let message2) = $1 else {
                    return false
                }
                
                return message1.time! > message2.time!
            }
        }
    }
    
    func delete(message: DeleteMessage, on eventLoop: EventLoop) -> EventLoopFuture<Void> {
        let guid = message.id, parts = message.parts ?? []
        let fullMessage = parts.count == 0
        
        return IMMessage.imMessage(withGUID: guid, on: eventLoop).map { message -> Void in
            guard let message = message else {
                return
            }
            
            if fullMessage {
                IMDaemonController.shared()!.deleteMessage(withGUIDs: [guid], queryID: NSString.stringGUID())
            } else {
                let chatItems = message._imMessageItem._newChatItems()!
                
                let items: [IMChatItem] = parts.compactMap {
                    if chatItems.count <= $0 { return nil }
                    return chatItems[$0]
                }
                
                let newItem = self.imChat.chatItemRules._item(withChatItemsDeleted: items, fromItem: message._imMessageItem)!
                
                IMDaemonController.shared()!.updateMessage(newItem)
            }
        }
    }
    
    func send(message: CreateMessage, on eventLoop: EventLoop) -> EventLoopFuture<BulkMessageRepresentation> {
        let promise = eventLoop.makePromise(of: BulkMessageRepresentation.self)
        
        ERAttributedString(from: message.parts, on: eventLoop).whenSuccess { result in
            let text = result.string
            let fileTransferGUIDs = result.transferGUIDs
            
            if text.length == 0 {
                promise.fail(BarcelonaError(code: 400, message: "Cannot send an empty message"))
                return
            }
            
            var subject: NSMutableAttributedString?
            
            if let rawSubject = message.subject {
                subject = NSMutableAttributedString(string: rawSubject)
            }
            
            /** Creates a base message using the computed attributed string */
            
            let message = IMMessage.instantMessage(withText: text, messageSubject: subject, fileTransferGUIDs: fileTransferGUIDs, flags: flagsForCreation(message, transfers: fileTransferGUIDs).rawValue)
            
            DispatchQueue.main.async {
                /** Split the base message into individual messages if it contains rich link(s) */
                guard let messages = message.messagesBySeparatingRichLinks() as? [IMMessage] else {
                    print("Malformed message result when separating rich links at \(message)")
                    return
                }
                
                messages.forEach { message in
                    self.imChat._sendMessage(message, adjustingSender: true, shouldQueue: true)
                }
                
                messages.bulkRepresentation(in: self.id).cascade(to: promise)
            }
        }
        
        return promise.futureResult
    }
}

extension Chat {
    var participantIDs: BulkHandleIDRepresentation {
        BulkHandleIDRepresentation(handles: participants)
    }
}

func chatToRepresentation(_ backing: IMChat, skinny: Bool = false) -> Chat {
    return .init(backing)
}
