//
//  Chat.swift
//  imcore-rest
//
//  Created by Eric Rabil on 7/23/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import Combine
import IMCore
import NIO

import Vapor

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

struct BulkChatRepresentation: Content, BulkChatRepresentatable {
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

struct ChatIDRepresentation: Content {
    var chat: String
}

enum MessagePartType: String, Codable {
    case text = "text"
    case attachment = "attachment"
}

struct MessagePart: Content {
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
    var guid: String { get set }
}

protocol ChatConfigurationRepresentable {
    var readReceipts: Bool { get set }
    var ignoreAlerts: Bool { get set }
}

struct ChatConfigurationRepresentation: Content, ChatConfigurationRepresentable {
    var groupID: String
    var readReceipts: Bool
    var ignoreAlerts: Bool
}

struct DeleteMessage: Codable, MessageIdentifiable {
    var guid: String
    var parts: [Int]?
}

extension MessageIdentifiable {
    func resolveChatGroupID(on eventLoop: EventLoop) -> EventLoopFuture<String?> {
        DBReader.shared.chatGroupID(forMessageGUID: guid)
    }
    
    func resolveChat(on eventLoop: EventLoop) -> EventLoopFuture<Chat?> {
        Chat.chat(forMessage: guid, on: eventLoop)
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

struct Chat: Codable, ChatConfigurationRepresentable {
    init(_ backing: IMChat) {
        joinState = backing.joinState
        roomName = backing.roomName
        displayName = backing.displayName
        groupID = backing.groupID
        participants = (backing.participantHandleIDs() ?? []).map {
            $0.starts(with: "e:") ? $0.substring(from: .init(encodedOffset: 2)) : $0
        }
        lastAddressedHandleID = backing.lastAddressedHandleID
        unreadMessageCount = backing.unreadMessageCount
        messageFailureCount = backing.messageFailureCount
        service = backing.account?.serviceName
        lastMessage = backing.lastFinishedMessage?.description(forPurpose: 0x2, inChat: backing, senderDisplayName: backing.lastMessage?.sender._displayNameWithAbbreviation)
        lastMessageTime = (backing.lastFinishedMessage?.time.timeIntervalSince1970 ?? 0) * 1000
        style = backing.chatStyle
        readReceipts = backing.readReceipts
        ignoreAlerts = backing.ignoreAlerts
        
        backing.messageCount
    }
    
    public static func chat(forMessage guid: String, on eventLoop: EventLoop) -> EventLoopFuture<Chat?> {
        DBReader.shared.chatGroupID(forMessageGUID: guid).map {
            guard let groupID = $0 else {
                return nil
            }
            
            return Registry.sharedInstance.chat(withGroupID: groupID)
        }
    }
    
    var groupID: String
    var joinState: Int64
    var roomName: String?
    var displayName: String?
    var participants: [String]
    var lastAddressedHandleID: String?
    var unreadMessageCount: UInt64?
    var messageFailureCount: UInt64?
    var service: String?
    var lastMessage: String?
    var lastMessageTime: Double
    var style: UInt8
    var readReceipts: Bool
    var ignoreAlerts: Bool
    
    public func imChat() -> IMChat {
        Registry.sharedInstance.imChat(withGroupID: groupID)!
    }
    
    func messages(before: String? = nil, limit: UInt64? = nil) -> EventLoopFuture<[ChatItem]> {
            guard let ROWID = $0 else {
                return messageQuerySystem.next().makeSucceededFuture([])
        DBReader.shared.rowIDs(forGroupID: groupID).flatMap { ROWIDs -> EventLoopFuture<[String]> in
            return DBReader.shared.newestMessageGUIDs(inChatROWIDs: ROWIDs, beforeMessageGUID: before, limit: Int(limit ?? 100))
            }
            
        }.flatMap {
            IMMessage.messages(withGUIDs: $0, on: messageQuerySystem.next())
        }.flatMap {
            ERIndeterminateIngestor.ingest($0, in: self.groupID)
        }
    }
    
    func delete(message: DeleteMessage, on eventLoop: EventLoop) -> EventLoopFuture<Void> {
        let guid = message.guid, parts = message.parts ?? []
        let fullMessage = parts.count == 0
        
        return IMMessage.message(withGUID: guid, on: eventLoop).map { message -> Void in
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
                
                let newItem = self.imChat().chatItemRules._item(withChatItemsDeleted: items, fromItem: message._imMessageItem)!
                
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
                promise.fail(Abort(.badRequest))
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
                    self.imChat()._sendMessage(message, adjustingSender: true, shouldQueue: true)
                }
                
                messages.bulkRepresentation(in: self.groupID).cascade(to: promise)
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
