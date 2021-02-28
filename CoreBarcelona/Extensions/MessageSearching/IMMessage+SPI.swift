//
//  IMMessage+SPI.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 8/16/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import NIO
import os.log

extension Array where Element == IMMessage {
    func bulkRepresentation(in chat: String) -> EventLoopFuture<BulkMessageRepresentation> {
        ERIndeterminateIngestor.ingest(messageLike: self, in: chat).map {
            $0.representation
        }
    }
}

private let queue = DispatchQueue.init(label: "com.ericrabil.imd-resolver.messages")
private let message_log = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "IMMessage+SPI")

public extension IMMessage {
    /**
     Takes an IMMessageItem that has no context object and resolves it into a fully formed IMMessage
     */
    static func message(fromUnloadedItem item: IMMessageItem, withSubject subject: NSMutableAttributedString? = nil) -> IMMessage? {
        var rawSender: String? = item.sender()
        
        if item.sender() == nil, item.isFromMe(), let suitableHandle = Registry.sharedInstance.suitableHandle(for: item.service) {
            rawSender = suitableHandle.id
            item.accountID = suitableHandle.account.uniqueID
        }
        
        guard let senderID = rawSender, let account = item.imAccount, let sender = Registry.sharedInstance.imHandle(withID: senderID, onAccount: account) else {
            return nil
        }
        
        return IMMessage(fromIMMessageItem: item, sender: sender, subject: subject)!
    }
    
    static func message(withGUID guid: String, on eventLoop: EventLoop? = nil) -> EventLoopFuture<ChatItem?> {
        return messages(withGUIDs: [guid], on: eventLoop ?? messageQuerySystem.next()).map { results in
            results.first
        }
    }
    
    static func messages(withGUIDs guids: [String], in chat: String? = nil, on eventLoop: EventLoop? = nil) -> EventLoopFuture<[ChatItem]> {
        let eventLoop = eventLoop ?? messageQuerySystem.next()
        if guids.count == 0 {
            return eventLoop.makeSucceededFuture([])
        }
        
        return eventLoop.flatSubmit { () -> EventLoopFuture<[ChatItem]> in
            if ERBarcelonaManager.isSimulation {
                return IMChatHistoryController.sharedInstance()!.loadMessages(withGUIDs: guids, on: eventLoop).map { message -> [IMItem] in
                    return message.compactMap {
                        $0._imMessageItem
                    }
                }.flatMap { items -> EventLoopFuture<[ChatItem]> in
                    ERIndeterminateIngestor.ingest(items, in: chat)
                }
            } else {
                return ERLoadAndParseIMDMessageRecordRefsWithGUIDs(guids, in: chat)
            }
        }
    }
}
