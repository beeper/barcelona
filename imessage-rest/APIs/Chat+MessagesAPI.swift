//
//  Chat+MessagesAPI.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/6/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import GRDB
import Foundation
import IMCore
import DataDetectorsCore
import Vapor
import CoreFoundation

extension Sequence where Element: NSAttributedString {
    func join(withSeparator separator: NSAttributedString) -> NSAttributedString {
        let finalString = NSMutableAttributedString()
        for (index, string) in enumerated() {
            if index > 0 {
                finalString.append(separator)
            }
            finalString.append(string)
        }
        return finalString
    }
}

enum MessagePartType: String, Codable {
    case text = "text"
    case attachment = "attachment"
}

struct MessagePart: Content {
    var type: MessagePartType
    var details: String
}

struct CreateMessage: Content {
    var subject: String?
    var parts: [MessagePart]
    var isAudioMessage: Bool?
    var flags: CLongLong?
    var ballonBundleID: String?
    var payloadData: String?
    var expressiveSendStyleID: String?
}

struct CreateChat: Content {
    var participants: [String]
}

struct RenameChat: Content {
    var name: String?
}

struct OKResult: Content {
    var ok: Bool
}

struct DeleteMessage: Content {
    var guid: String
    var parts: [Int]?
}

struct DeleteMessageRequest: Content {
    var messages: [DeleteMessage]
}

private func flagsForCreation(_ creation: CreateMessage, transfers: [String]) -> FullFlagsFromMe {
    if let _ = creation.ballonBundleID { return .richLink }
    if let audio = creation.isAudioMessage { if audio { return .audioMessage } }
    if transfers.count > 0 || creation.parts.contains(where: { $0.type == .attachment }) { return .attachments }
    return .textOrPluginOrStickerOrImage
}

func bindMessagesAPI(_ chat: RoutesBuilder) {
    let messages = chat.grouped("messages")
    
    // MARK: - Bulk
    
    /**
     Query messages in a chat
     */
    messages.get { req -> EventLoopFuture<BulkChatItemRepresentation> in
        guard let guid = req.parameters.get("guid") else { throw Abort(.badRequest) }
        guard let chat = IMChatRegistry.sharedInstance()?._chatInstance(forGUID: guid) else { throw Abort(.notFound) }
        let messageGUID = try? req.query.get(String.self, at: "before")
        let limit = (try? req.query.get(UInt64.self, at: "limit")) ?? 75
        
        let promise = req.eventLoop.makePromise(of: BulkChatItemRepresentation.self)
        
        chat.loadMessages(before: messageGUID, limit: limit) { messages in
            promise.succeed(BulkChatItemRepresentation(items: messages))
        }
        
        return promise.futureResult
    }
    
    /**
     Create a ChatItem
     */
    messages.grouped(ThrottlingMiddleware(allotment: 30, expiration: 5)).post { req -> EventLoopFuture<BulkMessageRepresentation> in
        guard let creation = try? req.content.decode(CreateMessage.self), let guid = req.parameters.get("guid") else { throw Abort(.badRequest) }
        guard let chat = IMChatRegistry.sharedInstance()?._chatInstance(forGUID: guid) else { throw Abort(.notFound) }
        
        let promise = req.eventLoop.makePromise(of: BulkMessageRepresentation.self)
        
        ERAttributedString(from: creation.parts, on: req.eventLoop).whenSuccess { result in
            let text = result.string
            let fileTransferGUIDs = result.transferGUIDs
            
            if text.length == 0 {
                promise.fail(Abort(.badRequest))
                return
            }
            
            var subject: NSMutableAttributedString?
            
            if let rawSubject = creation.subject {
                subject = NSMutableAttributedString(string: rawSubject)
            }
            
            /** Creates a base message using the computed attributed string */
            
            let message = IMMessage.instantMessage(withText: text, messageSubject: subject, fileTransferGUIDs: fileTransferGUIDs, flags: flagsForCreation(creation, transfers: fileTransferGUIDs).rawValue)
            
            DispatchQueue.main.async {
                /** Split the base message into individual messages if it contains rich link(s) */
                guard let messages = message.messagesBySeparatingRichLinks() as? [IMMessage] else {
                    print("Malformed message result when separating rich links at \(message)")
                    promise.fail(Abort(.internalServerError))
                    return
                }
                
                messages.forEach { message in
                    chat._sendMessage(message, adjustingSender: true, shouldQueue: true)
                }
                
                promise.succeed(BulkMessageRepresentation(messages, chatGUID: guid))
            }
        }
        
        return promise.futureResult
    }
    
    /**
     Delete a message or subpart from the message
     */
    messages.delete { req -> EventLoopFuture<OKResult> in
        guard let deletion = try? req.content.decode(DeleteMessageRequest.self), let chatGUID = req.parameters.get("guid") else { throw Abort(.badRequest) }
        guard let chat = IMChatRegistry.sharedInstance()?._chatInstance(forGUID: chatGUID) else { throw Abort(.notFound) }
        
        let promise = req.eventLoop.makePromise(of: OKResult.self)
        
        let resolutions = deletion.messages.map { request -> EventLoopFuture<OKResult> in
            let future = req.eventLoop.makePromise(of: OKResult.self)
            
            let guid = request.guid, parts = request.parts ?? []
            let fullMessage = parts.count == 0
            
            chat.loadMessage(withGUID: guid) { message in
                guard let message = message else {
                    future.fail(Abort(.notFound))
                    return
                }
                
                if fullMessage {
                    IMDaemonController.shared()!.deleteMessage(withGUIDs: [guid], queryID: NSString.stringGUID() as String)
                } else {
                    let chatItems = message._imMessageItem._newChatItems()!
                    
                    let items: [IMChatItem] = parts.compactMap {
                        if chatItems.count <= $0 { return nil }
                        return chatItems[$0]
                    }
                    
                    let newItem = chat.chatItemRules._item(withChatItemsDeleted: items, fromItem: message._imMessageItem)!
                    
                    print(IMDaemonController.shared()!.updateMessage(newItem))
                }
                
                future.succeed(OKResult(ok: false))
            }
            
            return future.futureResult
        }
        
        EventLoopFuture<OKResult>.whenAllSucceed(resolutions, on: req.eventLoop).whenComplete { result in
            switch result {
            case .failure(let error):
                promise.fail(error)
                break
            case .success(let _):
                promise.succeed(OKResult(ok: true))
            }
        }
        
        return promise.futureResult
    }
    
    // MARK: - Specific
    
    let message = messages.grouped(":messageGUID")
    
    bindTapbacksAPI(message)
    
    /**
     Query a specific message
     */
    message.get { req -> EventLoopFuture<MessageRepresentation> in
        guard let chatGUID = req.parameters.get("guid"), let messageGUID = req.parameters.get("messageGUID") else { throw Abort(.badRequest) }
        guard let chat = IMChatRegistry.sharedInstance()?._chatInstance(forGUID: chatGUID) else { throw Abort(.notFound) }
        
        let promise = req.eventLoop.makePromise(of: MessageRepresentation.self)
        
        chat.loadMessage(withGUID: messageGUID) { message in
            guard let message = message else {
                promise.fail(Abort(.badRequest))
                return
            }
            
            promise.succeed(MessageRepresentation(message, chatGUID: chatGUID))
        }
        
        return promise.futureResult
    }
}

// MARK: - Tapbacks
private func bindTapbacksAPI(_ message: RoutesBuilder) {
    let tapbacks = message.grouped("tapbacks")
    
    /**
     Send a tapback
     */
    tapbacks.post { req -> EventLoopFuture<HTTPStatus> in
        guard let chatGUID = req.parameters.get("guid"), let messageGUID = req.parameters.get("messageGUID"), let part = try? req.query.get(Int.self, at: "part"), let ackType = try? req.query.get(Int.self, at: "type") else { throw Abort(.badRequest) }
        guard let chat = IMChatRegistry.sharedInstance()?._chatInstance(forGUID: chatGUID) else { throw Abort(.notFound) }
        
        let debugItemType = try? req.query.get(UInt8.self, at: "itemType")
        let promise = req.eventLoop.makePromise(of: HTTPStatus.self)
        
        chat.tapback(guid: messageGUID, index: part, type: ackType, overridingItemType: debugItemType) { error in
            guard let error = error else {
                return promise.succeed(.ok)
            }
            
            promise.fail(error)
        }
        
        return promise.futureResult
    }
    
    tapbacks.get { req -> EventLoopFuture<BulkTapbackRepresentation> in
        guard let chatGUID = req.parameters.get("guid"), let chat = IMChatRegistry.sharedInstance()!._chatInstance(forGUID: chatGUID), let messageGUID = req.parameters.get("messageGUID"), let part = try? req.query.get(Int.self, at: "part") else {
            throw Abort(.notFound)
        }
        
        let reader = DBReader(pool: db, eventLoop: req.eventLoop)
        let promise = req.eventLoop.makePromise(of: BulkTapbackRepresentation.self)
        
        chat.loadMessage(withGUID: messageGUID) { message in
            guard let _ = message else {
                promise.fail(Abort(.notFound))
                return
            }
            
            reader.tapbacks(for: "p:\(part)/\(messageGUID)").whenComplete { result in
                switch (result) {
                case .failure(let error):
                    print(error)
                    promise.fail(Abort(.internalServerError))
                    break
                case .success(let representations):
                    print(representations)
                    promise.succeed(representations)
                    break
                }
            }
        }
        
        return promise.futureResult
    }
}
