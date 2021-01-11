//
//  MessageEvents.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/9/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import CoreBarcelona
import IMCore
import os.log
import NIO

private let IMChatMessageDidChangeNotification = NSNotification.Name(rawValue: "__kIMChatMessageDidChangeNotification")
private let IMChatItemsDidChangeNotification = NSNotification.Name(rawValue: "__kIMChatItemsDidChangeNotification")
private let IMChatMessageReceivedNotification = NSNotification.Name(rawValue: "__kIMChatMessageReceivedNotification")

private let messageKey = "__kIMChatValueKey";
private let IMChatItemsRemoved = "__kIMChatItemsRemoved";
private let IMChatItemsInserted = "__kIMChatItemsInserted";
private let IMChatItemsRegenerate = "__kIMChatItemsRegenerate";
private let IMChatItemsReload = "__kIMChatItemsReload";
private let IMChatItemsOldItems = "__kIMChatItemsOldItems";

private let IMChatValueKey = AnyHashable("__kIMChatValueKey");

private let log_messageEvents = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "MessageEvents")
private let log_shouldLog = false

let ChangedItemsExclusion = [
//    IMTextMessagePartChatItem.self,
//    IMAttachmentMessagePartChatItem.self,
    IMMessageAcknowledgmentChatItem.self,
    IMAssociatedMessageItem.self,
//    IMMessageStatusChatItem.self,
]

//private let ChangedItemsExclusion = [AnyClass.Type]()

enum MessageDebounceCategory {
    case statusChanged
}

/**
 Tracks events related to IMMessage
 */
class MessageEvents: EventDispatcher {
    private let debouncer = CategorizedDebounceManager<MessageDebounceCategory>([
        .statusChanged: Double(1 / 10)
    ])
    
    override func wake() {
        addObserver(forName: IMChatItemsDidChangeNotification) {
            self.itemsChanged($0)
        }
        
//        addObserver(forName: .init(rawValue: "ERIncomingItem")) {
//            guard let obj = $0.userInfo?["item"] as? NSObject, let chat = $0.object as? IMChat else {
//                return
//            }
//
//            self.process(inserted: [obj], in: chat, on: .itemsReceived)
//        }
        
        
//        addObserver(forName: IMChatMessageDidChangeNotification) {
//            print($0)
//        }
        
//        addObserver(forName: IMChatMessageReceivedNotification) {
//            print($0)
//        }
        
//        addObserver(forName: IMChatMessageDidChangeNotification) {
//            guard let chat = $0.object as? IMChat, let message = $0.userInfo?[IMChatValueKey] as? IMMessage else {
//                return
//            }
//
//            self.debouncer.receive(guid: message.guid) {
//                self.messageUpdated(message, chat: chat)
//            }
//        }
    }
    
    private func messageUpdated(_ message: IMMessage, chat: IMChat) {
        ERIndeterminateIngestor.ingest(message, in: chat.id).whenSuccess {
            guard let item = $0 else {
                return
            }
            
            StreamingAPI.shared.dispatch(eventFor(itemsReceived: BulkChatItemRepresentation(items: [item])))
        }
    }
    
    /**
     Dispatches incoming transcript items
     */
    private func process(inserted items: [NSObject], in chat: IMChat, on event: Event<BulkChatItemRepresentation>.EventType) {
        var messageGUIDs: [String] = []
        var statusChanges: [IMMessageStatusChatItem] = []
        
        let wrapped = items.compactMap { transcriptItem -> EventLoopFuture<ChatItem?>? in
            if log_shouldLog { os_log("👨🏻‍💻 Processing inserted IMTranscriptItem %@", transcriptItem, log_messageEvents) }
            
            switch (transcriptItem) {
            case let item as IMMessagePartChatItem:
                if let guid = item.message?.guid ?? item._item()?.guid {
                    if !messageGUIDs.contains(guid) {
                        messageGUIDs.append(guid)
                    }
                }
                return nil
            case let item as IMMessageStatusChatItem:
                statusChanges.append(item)
                return nil
            default:
                return ERIndeterminateIngestor.ingest(transcriptItem, in: chat.id)
            }
        }
        
        let pendingMessages = messageGUIDs.er_chatItems(in: chat.id)
        
        EventLoopFuture<ChatItem?>.whenAllSucceed(wrapped, on: eventProcessing_eventLoop.next()).map { $0.compactMap { $0 } }.whenSuccess { chatItems in
            pendingMessages.whenSuccess { messageChatItems in
                if chatItems.count == 0, messageChatItems.count == 0 {
                    return
                }
                
                var merged = [ChatItem]()
                merged.append(contentsOf: chatItems)
                merged.append(contentsOf: messageChatItems)
                
                StreamingAPI.shared.dispatch(Event<BulkChatItemRepresentation>.init(type: event, data: BulkChatItemRepresentation(items: merged)))
            }
        }
        
        if statusChanges.count == 0 {
            return
        }
        
        EventLoopFuture<StatusChatItem?>.whenAllSucceed(statusChanges.map {
            ERIndeterminateIngestor.ingest($0, in: chat.id)
        }, on: eventProcessing_eventLoop.next()).map {
            $0.compactMap { $0 }
        }.whenSuccess {
            if $0.count == 0 { return }
            $0.forEach { status in
                self.debouncer.submit(status.itemID, category: .statusChanged) {
                    StreamingAPI.shared.dispatch(eventFor(itemStatusChanged: status))
                }
            }
        }
    }
    
    /**
     Receives participant change, group name change, date chat item
     */
    private func itemsChanged(_ notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: NSObject] else { return }
        guard let chat = notification.object as? IMChat else { return }
        
        userInfo.forEach {
            guard let set = $0.value as? IndexSet else { return }
            
            switch ($0.key) {
            case IMChatItemsRegenerate:
                fallthrough;
            case IMChatItemsReload:
                fallthrough;
            case IMChatItemsInserted:
                let key = $0.key
                
                self.process(inserted: set.compactMap { index -> NSObject? in
                    guard let item = chat.chatItems[safe: index] else {
                        os_log("⁉️ Bad index when parsing chat items!", type: .error, log_messageEvents)
                        return nil
                    }
                    
                    if key == IMChatItemsInserted {
                        if let _ = item as? IMMessagePartChatItem {
                            return nil
                        }
                        
                        if let _ = item as? IMAssociatedMessageChatItem {
                            return nil
                        }
                    }

                    return item
                }, in: chat, on: key == IMChatItemsInserted ? .itemsReceived : .itemsUpdated)
            case IMChatItemsRemoved:
                break;
            default:
                return
            }
        }
    }
}
