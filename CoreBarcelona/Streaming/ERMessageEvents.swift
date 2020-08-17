//
//  ERMessageEvents.swift
//  imessage-rest
//
//  Created by Eric Rabil on 8/12/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import os.log

internal let ERChatMessageReceivedNotification = NSNotification.Name(rawValue: "ERChatMessageReceivedNotification")
internal let ERChatMessagesReceivedNotification = NSNotification.Name(rawValue: "ERChatMessagesReceivedNotification")
internal let ERChatMessageSentNotification = NSNotification.Name(rawValue: "ERChatMessageSentNotification")
internal let ERChatMessagesUpdatedNotification = NSNotification.Name(rawValue: "ERChatMessagesUpdatedNotification")
internal let ERChatMessageUpdatedNotification = NSNotification.Name(rawValue: "ERChatMessageUpdatedNotification")

private let log_messageEvents = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "ERMessageEvents")

class ERMessageEvents: EventDispatcher {
    override func wake() {
        addObserver(forName: ERChatMessageReceivedNotification) {
            guard let item = $0.object as? IMItem, let chat = ($0.userInfo as? [String: Any])?["chat"] as? String else {
                return
            }

            self.messageReceived(item, inChat: chat)
        }

        addObserver(forName: ERChatMessagesReceivedNotification) {
            guard let items = $0.object as? [IMItem], let chat = ($0.userInfo as? [String: Any])?["chat"] as? String else {
                return
            }

            self.messagesReceived(items, inChat: chat)
        }
        
        /// Tapbacks that are sent from me, on other devices, do not get received by other handlers. This handler receives tapbacks on all devices.
        addObserver(forName: ERChatMessageSentNotification) {
            guard let chat = ($0.userInfo as? [String: Any])?["chat"] as? String else {
                return
            }
            
            if let associated = $0.object as? IMAssociatedMessageItem {
                self.messagesReceived([associated], inChat: chat, overrideFromMe: true)
            }
        }
        
        addObserver(forName: ERChatMessagesUpdatedNotification) {
            guard let items = $0.object as? [IMItem], let chat = ($0.userInfo as? [String: Any])?["chat"] as? String else {
                return
            }
            
            self.messagesUpdated(items, inChat: chat)
        }
        
        addObserver(forName: ERChatMessageUpdatedNotification) {
            guard let item = $0.object as? IMItem, let chat = ($0.userInfo as? [String: Any])?["chat"] as? String else {
                return
            }
            
            self.messageUpdated(item, inChat: chat)
        }
    }
    
    /** Counts as a new message */
    private func messageReceived(_ item: IMItem, inChat chatIdentifier: String) {
        messagesReceived([item], inChat: chatIdentifier)
    }
    
    /** Counts as a new message */
    private func messagesReceived(_ items: [IMItem], inChat chatIdentifier: String, overrideFromMe: Bool = false) {
        let chat = IMChatRegistry.shared.existingChat(withChatIdentifier: chatIdentifier)!
        
        items.forEach { item in
            if !ChangedItemsExclusion.contains(where: {
                item.isKind(of: $0)
            }) {
                return
            }
            
            if item is IMAssociatedMessageItem, item.isFromMe, !overrideFromMe {
                return
            }
            
            chat.loadMessage(withGUID: item.guid) { message in
                guard let parsed = self.parse(message ?? item._newChatItems(), chatGroupID: chat.groupID) else {
                    return
                }
                
                StreamingAPI.shared.dispatch(eventFor(itemsReceived: BulkChatItemRepresentation(items: parsed)), to: nil)
            }
        }
    }
    
    /** Counts as an update */
    private func messagesUpdated(_ items: [IMItem], inChat chatIdentifier: String) {
        let chat = IMChatRegistry.shared.existingChat(withChatIdentifier: chatIdentifier)!
        
        items.forEach { item in
            IMChatRegistry.shared.existingChat(withChatIdentifier: chatIdentifier)!.loadMessage(withGUID: item.guid) { message in
                guard let parsed = self.parse(message ?? item._newChatItems(), chatGroupID: chat.groupID) else {
                    return
                }
                
                StreamingAPI.shared.dispatch(eventFor(itemsUpdated: BulkChatItemRepresentation(items: parsed)), to: nil)
            }
        }
    }
    
    private func parse(_ unknown: Any?, chatGroupID: String) -> [ChatItem]? {
        if let array = unknown as? [NSObject] {
            return parseArrayOf(chatItems: array, withGroupID: chatGroupID)
        } else if let item = unknown as? NSObject, let parsed = wrapChatItem(unknownItem: item, withChatGroupID: chatGroupID) {
            return [parsed]
        } else {
            return nil
        }
    }
    
    /** Counts as an update */
    private func messageUpdated(_ item: IMItem, inChat chatIdentifier: String) {
        messagesUpdated([item], inChat: chatIdentifier)
    }
}
