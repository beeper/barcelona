//
//  ERChatSubscriptionWatcher.swift
//  imessage-rest
//
//  Created by Eric Rabil on 8/11/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import UserNotifications
import Foundation
import IMCore

private let IMChatRegistryDidLoadNotification = NSNotification.Name(rawValue: "__kIMChatRegistryDidLoadNotification")
private let IMChatRegistryDidRegisterChatNotification = NSNotification.Name(rawValue: "__kIMChatRegistryDidRegisterChatNotification")

/**
 Ensures all chats are accessed in a way that produces notifications for them.
 */
class ERChatSubscriptionWatcher {
    static let shared: ERChatSubscriptionWatcher = ERChatSubscriptionWatcher()
    static var sharedInstance: ERChatSubscriptionWatcher {
        shared
    }
    
    private init() {
        /**
         Called when the chat registry finishes loading. Also marks the ready point for the service.
         */
        NotificationCenter.default.addObserver(forName: IMChatRegistryDidLoadNotification, object: nil, queue: nil) { notif in
            self.ensureAllChatsAreSubscribed()
            ERSharedBlockList()._connect()
            
            try! ERHTTPServer.shared.start()
        }
        
        /**
         Called when a chat is created – subscribes to it
         */
        NotificationCenter.default.addObserver(forName: IMChatRegistryDidRegisterChatNotification, object: nil, queue: nil) { notif in
            guard let chat = notif.object as? IMChat else { return }
            self.ensureSubscribed(to: chat)
        }
    }
    
    /**
     Iterates over all loaded chats and subscribes to them
     */
    private func ensureAllChatsAreSubscribed() {
        IMChatRegistry.sharedInstance()!._allCreatedChats().forEach { ensureSubscribed(to: $0) }
    }
    
    /**
     Subscribe to a single chat
     */
    private func ensureSubscribed(to chat: IMChat) {
        guard let _ = chat.chatItems else { return }
    }
}
