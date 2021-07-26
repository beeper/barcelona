//
//  MessageEvents.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/9/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import Barcelona
import IMCore
import os.log

private let messageKey = "__kIMChatValueKey";
private let IMChatItemsRemoved = "__kIMChatItemsRemoved";
private let IMChatItemsInserted = "__kIMChatItemsInserted";
private let IMChatItemsRegenerate = "__kIMChatItemsRegenerate";
private let IMChatItemsReload = "__kIMChatItemsReload";
private let IMChatItemsOldItems = "__kIMChatItemsOldItems";

private let IMChatValueKey = AnyHashable("__kIMChatValueKey");

private let log_messageEvents = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "MessageEvents")

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
        addObserver(forName: .IMChatItemsDidChange) {
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
        
        addObserver(forName: .init("__kIMChatMessageDidChangeNotification")) {
            guard let chat = $0.object as? IMChat, let message = $0.userInfo?[IMChatValueKey] as? IMMessage else {
                return
            }
//
//            self.debouncer.receive(guid: message.guid) {
            self.messageUpdated(message, chat: chat)
//            }
        }
    }
    
    private func messageUpdated(_ message: IMMessage, chat: IMChat) {
        BLIngestObject(message, inChat: chat.id).whenSuccess { item in
            if message.isFromMe && message.isSent {
                self.bus.dispatch(.itemsUpdated([item.eraseToAnyChatItem()]))
            } else {
                self.bus.dispatch(.itemsReceived([item.eraseToAnyChatItem()]))
            }
        }
    }
    
    /**
     Dispatches incoming transcript items
     */
    private func process(inserted items: [NSObject], in chat: IMChat, on event: Event) {
        var messageGUIDs: Set<String> = .init()
        var statusChanges: [IMMessageStatusChatItem] = []
        
        for item in items {
            log_messageEvents.debug("👨🏻‍💻 Processing inserted IMItem %@", item)
            
            switch (item) {
            case _ as IMDateChatItem:
                break
            case _ as IMServiceChatItem:
                break
            case let item as IMMessagePartChatItem:
                if let guid = item.message?.guid ?? item._item()?.guid {
                    messageGUIDs.insert(guid)
                }
            case let item as IMTranscriptChatItem:
                if let guid = item.guid ?? item._item()?.guid {
                    messageGUIDs.insert(guid)
                }
            case let item as IMMessageStatusChatItem:
                statusChanges.append(item)
            default:
                print("asdf")
            }
        }
        
        if messageGUIDs.count > 0 {
            let pendingMessages = Array(messageGUIDs).er_chatItems(in: chat.id)
            
            pendingMessages.whenSuccess { chatItems in
                if chatItems.count == 0 {
                    return
                }
                
                var toDispatch: Event? = nil
                switch event {
                case .itemsUpdated(_):
                    toDispatch = .itemsUpdated(chatItems.map { $0.eraseToAnyChatItem() })
                case .itemsReceived(_):
                    toDispatch = .itemsReceived(chatItems.map { $0.eraseToAnyChatItem() })
                default:
                    break
                }
                
                guard let toDispatch = toDispatch else {
                    return
                }
                
                log_messageEvents.debug("dispatching items with type %@: %@", toDispatch.label, chatItems)
                
                self.bus.dispatch(toDispatch)
            }
        }
        
        if statusChanges.count == 0 {
            return
        }
        
        BLIngestObjects(statusChanges, inChat: chat.id).then { items in
            items.compactMap { $0 as? StatusChatItem }
        }.whenSuccess { items in
            guard items.count > 0 else {
                return
            }
            
            items.forEach { status in
                self.debouncer.submit(status.itemID, category: .statusChanged) {
                    self.bus.dispatch(.itemStatusChanged(status))
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
                    guard chat.chatItems.count > index else {
                        log_messageEvents.error("⁉️ Bad index when parsing chat items!")
                        return nil
                    }

                    return chat.chatItems[index]
                }, in: chat, on: key == IMChatItemsInserted ? .itemsReceived([]) : .itemsUpdated([]))
            case IMChatItemsRemoved:
                break;
            default:
                return
            }
        }
    }
}
