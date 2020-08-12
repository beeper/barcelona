//
//  MessageEvents.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/9/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import os.log

private let IMChatMessageDidChangeNotification = NSNotification.Name(rawValue: "__kIMChatMessageDidChangeNotification")
private let IMChatItemsDidChangeNotification = NSNotification.Name(rawValue: "__kIMChatItemsDidChangeNotification")
private let IMChatMessageReceivedNotification = NSNotification.Name(rawValue: "__kIMChatMessageReceivedNotification")

private let messageKey = "__kIMChatValueKey";
private let IMChatItemsRemoved = "__kIMChatItemsRemoved";
private let IMChatItemsInserted = "__kIMChatItemsInserted";
private let IMChatItemsRegenerate = "__kIMChatItemsRegenerate";
private let IMChatItemsReload = "__kIMChatItemsReload";
private let IMChatItemsOldItems = "__kIMChatItemsOldItems";

private let log_messageEvents = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "MessageEvents")

private let ChangedItemsExclusion = [
    IMTextMessagePartChatItem.self,
    IMAttachmentMessagePartChatItem.self,
    IMMessageAcknowledgmentChatItem.self,
    IMMessageStatusChatItem.self,
    IMTypingChatItem.self
]

class MessageEvents: EventDispatcher {
    override func wake() {
        addObserver(forName: IMChatItemsDidChangeNotification) {
            self.itemsChanged($0)
        }
        
        addObserver(forName: IMChatMessageDidChangeNotification) {
            self.messageSentOrReceived($0)
        }
    }
    
    /**
     Receives typing messages, attachments, acknowledgments, delivery, read
     */
    private func messageSentOrReceived(_ notification: Notification) {
        guard let chat = notification.object as? IMChat else { return }
        
        guard let userInfo = notification.userInfo as? [String: NSObject] else { return }
        guard let rawItem = userInfo[messageKey] else { return }
        
        guard let chatItem = wrapChatItem(unknownItem: rawItem, withChatGUID: chat.guid) else {
            return
        }
        
        StreamingAPI.shared.dispatch(eventFor(itemsReceived: BulkChatItemRepresentation(items: [chatItem])), to: nil)
    }
    
    /**
     Dispatches incoming transcript items
     */
    private func process(inserted transcriptItems: [IMTranscriptChatItem], in chat: IMChat) {
        let event = eventFor(itemsReceived: BulkChatItemRepresentation(items: transcriptItems.compactMap { transcriptItem -> ChatItem? in
            os_log("👨🏻‍💻 Processing inserted IMTranscriptItem of type %@", transcriptItem.className, log_messageEvents)
            
            return wrapChatItem(unknownItem: transcriptItem, withChatGUID: chat.guid)
        }))
        
        if (event.data?.items.count ?? 0) == 0 {
            return
        }
        
        StreamingAPI.shared.dispatch(event, to: nil)
    }
    
    /**
     Receives participant change, group name change, date chat item
     */
    private func itemsChanged(_ notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: NSObject] else { return }
        guard let chat = notification.object as? IMChat else { return }
        guard let oldItems = userInfo[IMChatItemsOldItems] as? [IMChatItem] else { return }
        
        userInfo.forEach {
            guard let set = $0.value as? NSIndexSet else { return }
            
            switch ($0.key) {
            case IMChatItemsRegenerate:
                break;
            case IMChatItemsReload:
                break;
            case IMChatItemsInserted:
                self.process(inserted: set.compactMap { index -> IMTranscriptChatItem? in
                    guard let item = chat.chatItems[safe: index] else {
                        os_log("⁉️ Bad index when parsing chat items!", type: .error, log_messageEvents)
                        return nil
                    }
                    
                    if ChangedItemsExclusion.contains(where: {
                        item.isKind(of: $0)
                    }) {
                        os_log("🚫 Discarding excluded chat item with class %@", type: .debug, item.className, log_messageEvents)
                        return nil
                    }
                    
                    switch item {
                    case is IMTextMessagePartChatItem:
                        return nil
                    case let item as IMTranscriptChatItem:
                        return item
                    default:
                        os_log("🤔 Unknown chat item received at MessageEvents.swift:itemsChanged with class %@", type: .info, item.className, log_messageEvents)
                        return nil
                    }
                }, in: chat)
                
                break;
            case IMChatItemsRemoved:
                let guids = Array(Set(set.compactMap { index in
                    oldItems[index]._item().guid
                }))
                if guids.count == 0 { return }
                
                StreamingAPI.shared.dispatch(eventFor(itemsRemoved: BulkMessageIDRepresentation(messages: guids)), to: nil)
                
                break;
            default:
                return
            }
        }
    }
}
