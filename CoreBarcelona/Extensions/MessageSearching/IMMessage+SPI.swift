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
private func objc_unretained<P: NSObject>(_ obj: Unmanaged<P>) -> P {
    return obj.takeUnretainedValue()
}

extension IMMessage {
    /**
     Takes an IMMessageItem that has no context object and resolves it into a fully formed IMMessage
     */
    static func message(fromUnloadedItem item: IMMessageItem) -> IMMessage? {
        var rawSender: String? = item.sender()
        
        if item.sender() == nil, item.isFromMe(), let suitableHandle = Registry.sharedInstance.suitableHandle(for: item.service) {
            rawSender = suitableHandle.id
            item.accountID = suitableHandle.account.uniqueID
        }
        
        guard let senderID = rawSender, let account = item.imAccount, let sender = Registry.sharedInstance.imHandle(withID: senderID, onAccount: account) else {
            return nil
        }
        
        let tracker = ERTrack(log: message_log, name: "messageFromIMMessageItem", format: "guid %@", item.guid)
        
        let message = IMMessage.init(fromIMMessageItem: item, sender: sender, subject: nil)!
        
        let IMMessageItemChatContext = NSClassFromString("IMMessageItemChatContext") as! NSObject.Type
        
        let context = IMMessageItemChatContext.init()
        context.setValue(sender, forKey: "_senderHandle")
        context.setValue(message, forKey: "_message")
        
        item.context = context
        
        tracker()
        
        return message
    }
    
    static func imMessage(withGUID guid: String, on eventLoop: EventLoop = messageQuerySystem.next()) -> EventLoopFuture<IMMessage?> {
        return imMessages(withGUIDs: [guid], on: eventLoop).map { results in
            results.first
        }
    }
        
    static func imMessages(withGUIDs guids: [String], on eventLoop: EventLoop = messageQuerySystem.next()) -> EventLoopFuture<[IMMessage]> {
        let promise = eventLoop.makePromise(of: [IMMessage].self)
        
        if ERBarcelonaManager.isSimulation {
            IMChatHistoryController.sharedInstance()!.loadMessages(withGUIDs: guids, on: eventLoop).cascade(to: promise)
        } else {
            IMSPIQueryIMMessageItemsWithGUIDsAndQOS(guids, QOS_CLASS_USER_INITIATED, queue) { results in
                guard let results = results else {
                    promise.succeed([])
                    return
                }
                
                print(results)

                promise.succeed(results.compactMap { item in
                    guard let messageItem = item as? IMMessageItem else {
                        print("fuck! \(item)")
                        return nil
                    }
                    
                    return IMMessage.message(fromUnloadedItem: messageItem)
                })
            }
        }
        
        return promise.futureResult
    }
    
    static func message(withGUID guid: String, on eventLoop: EventLoop = messageQuerySystem.next()) -> EventLoopFuture<ChatItem?> {
        return messages(withGUIDs: [guid], on: eventLoop).map { results in
            results.first
        }
    }
    
    static func messages(withGUIDs guids: [String], in chat: String? = nil, on eventLoop: EventLoop = messageQuerySystem.next()) -> EventLoopFuture<[ChatItem]> {
        if guids.count == 0 {
            return eventLoop.makeSucceededFuture([])
        }
        
        return eventLoop.flatSubmit { () -> EventLoopFuture<[IMItem]> in
            let queryTracker = ERTrack(log: .default, name: "Querying IMD for messages", format: "")
            
            var records: NSArray!
            
            if ERBarcelonaManager.isSimulation {
                return IMChatHistoryController.sharedInstance()!.loadMessages(withGUIDs: guids, on: eventLoop).map { message -> [IMItem] in
                    return message.compactMap {
                        $0._imMessageItem
                    }
                }
            } else {
                #if IMCORE_UNMANAGED
                var unmanagedRecords: Unmanaged<CFArray>?
                #endif
                
                if let imdRecordsRef = IMDMessageRecordCopyMessagesForGUIDs(guids) {
                    records = imdRecordsRef.takeUnretainedValue()
                    
                    #if IMCORE_UNMANAGED
                    unmanagedRecords = imdRecordsRef
                    #endif
                } else {
                    records = [IMItem]() as NSArray
                }
                
                queryTracker()
                
                os_log("IMMessage+spi:messages(withGUIDs) got %d records from IMD", records.count)
                
                let mapTracker = ERTrack(log: .default, name: "Mapping records to IMCore objects", format: "")
                
                let transformed: [IMItem] = records.map { record -> IMItem in
                    #if IMCORE_UNMANAGED
                    let item = IMDCreateIMItemFromIMDMessageRecordRefWithServiceResolve(record, nil, nil, nil, nil) as! IMItem
                    let unmanagedItem = Unmanaged.passUnretained(item)
                    unmanagedItem.release()
                    return item
                    #else
                    return IMDCreateIMItemFromIMDMessageRecordRefWithServiceResolve(record, nil, nil, nil, nil) as! IMItem
                    #endif
                }
                
                #if IMCORE_UNMANAGED
                if let unmanagedRecords = unmanagedRecords {
                    unmanagedRecords.release()
                }
                #endif
                
                mapTracker()
                
                return eventLoop.makeSucceededFuture(transformed)
            }
        }.flatMap { item -> EventLoopFuture<[ChatItem]> in
            let ingestTracker = ERTrack(log: .default, name: "IMMessage+SPI ingesting items", format: "")
            
            let ingestion = ERIndeterminateIngestor.ingest(item, in: chat)
            
            ingestion.whenSuccess { _ in
                ingestTracker()
            }
            
            return ingestion
        }.map {
            return $0
        }
    }
}
