//
//  IMMessage+SPI.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 8/16/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import IMDPersistence
import NIO

extension Array where Element == IMMessage {
    func bulkRepresentation(in chat: String) -> EventLoopFuture<BulkMessageRepresentation> {
        ERIndeterminateIngestor.ingest(messageLike: self, in: chat).map {
            BulkMessageRepresentation($0)
        }
    }
}

private let queue = DispatchQueue.init(label: "com.ericrabil.imd-resolver.messages")

extension IMMessage {
    /**
     Takes an IMMessageItem that has no context object and resolves it into a fully formed IMMessage
     */
    static func message(fromUnloadedItem item: IMMessageItem) -> IMMessage? {
        var rawSender: String? = item.sender()
        
        if item.sender() == nil, item.isFromMe(), let suitableHandle = Registry.sharedInstance.suitableHandle(for: item.service) {
            rawSender = suitableHandle.id
        }
        
        guard let senderID = rawSender, let sender = Registry.sharedInstance.imHandle(withID: senderID) else {
            return nil
        }
        
        let message = IMMessage.init(fromIMMessageItem: item, sender: sender, subject: nil)!
        
        let IMMessageItemChatContext = NSClassFromString("IMMessageItemChatContext") as! NSObject.Type
        
        let context = IMMessageItemChatContext.init()
        context.setValue(sender, forKey: "_senderHandle")
        context.setValue(message, forKey: "_message")
        
        item.context = context
        
        return message
    }
    
    static func imMessage(withGUID guid: String, on eventLoop: EventLoop = messageQuerySystem.next()) -> EventLoopFuture<IMMessage?> {
            return imMessages(withGUIDs: [guid], on: eventLoop).map { results in
                results.first
            }
        }
        
    static func imMessages(withGUIDs guids: [String], on eventLoop: EventLoop = messageQuerySystem.next()) -> EventLoopFuture<[IMMessage]> {
        let promise = eventLoop.makePromise(of: [IMMessage].self)
        
        IMSPIQueryIMMessageItemsWithGUIDsAndQOS(guids, QOS_CLASS_USER_INITIATED, queue) { results in
            guard let results = results else {
                promise.succeed([])
                return
            }

            promise.succeed(results.compactMap { item in
                guard let messageItem = item as? IMMessageItem else {
                    print("fuck! \(item)")
                    return nil
                }
                
                let manager = Unmanaged.passUnretained(messageItem)
                
                let message = IMMessage.message(fromUnloadedItem: manager.takeUnretainedValue())

                manager.release()
                
                return message
            })
        }
        
        return promise.futureResult
    }
    
    static func message(withGUID guid: String, on eventLoop: EventLoop = messageQuerySystem.next()) -> EventLoopFuture<ChatItem?> {
        return messages(withGUIDs: [guid], on: eventLoop).map { results in
            results.first
        }
    }
    
    static func messages(withGUIDs guids: [String], on eventLoop: EventLoop = messageQuerySystem.next()) -> EventLoopFuture<[ChatItem]> {
        eventLoop.submit {
            IMDMessageRecordCopyMessagesForGUIDs(guids)
        }.map { records -> [Any] in
            records?.compactMap { record -> Any in
                IMDCreateIMItemFromIMDMessageRecordRefWithServiceResolve(record, nil, nil, nil, nil)
            } ?? [] as [Any]
        }.map { items in
            items.compactMap { result -> IMItem? in
                return result as? IMItem
            }
        }.flatMap {
            ERIndeterminateIngestor.ingest($0)
        }
    }
}
