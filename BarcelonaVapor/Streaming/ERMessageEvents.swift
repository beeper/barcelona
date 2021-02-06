//
//  ERMessageEvents.swift
//  imessage-rest
//
//  Created by Eric Rabil on 8/12/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import CoreBarcelona
import IMCore
import os.log
import NIO

private let log_messageEvents = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "ERMessageEvents")

class ERMessageEvents: EventDispatcher {
    override func wake() {
        addObserver(forName: ERChatMessageReceivedNotification) {
            guard let item = $0.object as? IMItem, let chat = ($0.userInfo as? [String: Any])?["chat"] as? String else {
                return
            }

            self.messageReceived(item, inChat: chat)
        }
        
        addObserver(forName: ERChatMessagesDeletedNotification) {
            guard let dict = $0.object as? [String: Any], let guids = dict["guids"] as? [String] else {
                return
            }
            
            self.messagesDeleted(guids)
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
    
    private func messagesDeleted(_ guids: [String]) {
        StreamingAPI.shared.dispatch(eventFor(itemsRemoved: BulkMessageIDRepresentation(messages: guids)))
    }
    
    /** Counts as a new message */
    private func messageReceived(_ item: IMItem, inChat chatIdentifier: String) {
        messagesReceived([item], inChat: chatIdentifier)
    }
    
    /** Counts as a new message */
    /**
     Intakes tangible messages, not transcript items.
     No typing items come here, no status items come here, no group items come here
     */
    private func messagesReceived(_ items: [IMItem], inChat chatIdentifier: String, overrideFromMe: Bool = false) {
        let chat = IMChatRegistry.shared.existingChat(withChatIdentifier: chatIdentifier)!
        
        EventLoopFuture<ChatItem?>.whenAllSucceed(items.compactMap { item -> EventLoopFuture<ChatItem?>? in
            if !ChangedItemsExclusion.contains(where: {
                item.isKind(of: $0)
            }) {
                return nil
            }
            
            if item is IMAssociatedMessageItem, item.isFromMe, !overrideFromMe {
                return nil
            }
            
            return itemGUIDAsChatItem(item.guid, in: chat.id)
        }, on: eventProcessing_eventLoop.next()).map {
            $0.compactMap { $0 }
        }.map {
            BulkChatItemRepresentation(items: $0)
        }.whenSuccess {
            if $0.items.count == 0 { return }
            StreamingAPI.shared.dispatch(eventFor(itemsReceived: $0), to: nil)
        }
    }
    
    /** Counts as an update */
    private func messagesUpdated(_ items: [IMItem], inChat chatIdentifier: String) {
        let chat = IMChatRegistry.shared.existingChat(withChatIdentifier: chatIdentifier)!
        
        EventLoopFuture<ChatItem?>.whenAllSucceed(items.map { item -> EventLoopFuture<ChatItem?> in
            return itemGUIDAsChatItem(item.guid, in: chat.id)
        }, on: eventProcessing_eventLoop.next()).map {
            $0.compactMap { $0 }
        }.whenSuccess {
            if $0.count == 0 { return }
            StreamingAPI.shared.dispatch(eventFor(itemsUpdated: BulkChatItemRepresentation(items: $0)), to: nil)
        }
    }
    
    /** Counts as an update */
    private func messageUpdated(_ item: IMItem, inChat chatIdentifier: String) {
        messagesUpdated([item], inChat: chatIdentifier)
    }
    
    private func itemGUIDAsChatItem(_ guid: String, in chatID: String) -> EventLoopFuture<ChatItem?> {
        IMMessage.message(withGUID: guid)
    }
}
