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
            guard let item = $0.object as? IMItem else {
                return
            }
            
            self.messageReceived(item)
        }
        
        addObserver(forName: ERChatMessagesReceivedNotification) {
            guard let items = $0.object as? [IMItem] else {
                return
            }
            
            self.messagesReceived(items)
        }
        
//        addObserver(forName: ERChatMessageSentNotification) {
//            guard let item = $0.object as? IMMessageItem else {
//                return
//            }
//
//            self.messageSent(item)
//        }
        
        addObserver(forName: ERChatMessagesUpdatedNotification) {
            guard let items = $0.object as? [IMItem] else {
                return
            }
            
            self.messagesUpdated(items)
        }
        
        addObserver(forName: ERChatMessageUpdatedNotification) {
            guard let item = $0.object as? IMItem else {
                return
            }
            
            self.messageUpdated(item)
        }
    }
    
    /** Counts as a new message */
    private func messageReceived(_ item: IMItem) {
        messagesReceived([item])
    }
    
    /** Counts as a new message */
    private func messagesReceived(_ items: [IMItem]) {
        items.forEach {
            if let chatItem = $0._newChatItems() as? IMChatItem {
                
            } else if let chatItems = $0._newChatItems() as? [IMChatItem] {
                
            } else {
                
            }
        }
    }
    
    /** Counts as a new message */
    private func messageSent(_ item: IMMessageItem) {
        print("message sent \(item.guid)")
    }
    
    /** Counts as an update */
    private func messagesUpdated(_ items: [IMItem]) {
        print("messages updated \(items.map { $0.guid })")
    }
    
    /** Counts as an update */
    private func messageUpdated(_ item: IMItem) {
        print("message updated \(item.guid)")
    }
}
