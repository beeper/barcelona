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
    private func messagesReceived(_ items: [IMItem], inChat chatIdentifier: String) {
        let chat = IMChatRegistry.shared.existingChat(withChatIdentifier: chatIdentifier)!
        
        items.forEach { item in
            chat.loadMessage(withGUID: item.guid) { message in
                guard let parsed = self.parse(message ?? item._newChatItems(), chatGUID: chat.guid) else {
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
                guard let parsed = self.parse(message ?? item._newChatItems(), chatGUID: chat.guid) else {
                    return
                }
                
                StreamingAPI.shared.dispatch(eventFor(itemsUpdated: BulkChatItemRepresentation(items: parsed)), to: nil)
            }
        }
    }
    
    private func parse(_ unknown: Any?, chatGUID: String) -> [ChatItem]? {
        if let array = unknown as? [NSObject] {
            return parseArrayOf(chatItems: array, withGUID: chatGUID)
        } else if let item = unknown as? NSObject, let parsed = wrapChatItem(unknownItem: item, withChatGUID: chatGUID) {
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
