//
//  IMChatRegistry+PinnedChats.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 2/13/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import IMCore

@available(iOS 14, macOS 10.16, watchOS 7, *)
public extension IMPinnedConversationsController {
    /// Unpins a chat if it is pinned
    /// - Parameter chat: chat to unpin
    func unpin(chat: IMChat) {
        if !pinnedConversationsContains(chat) {
            return
        }
        
        pinnedChats = pinnedChats.filter {
            $0.pinningIdentifier != chat.pinningIdentifier
        }
    }
    
    /// Pins a chat if it is not already pinned
    /// - Parameter chat: chat to pin
    func pin(chat: IMChat) {
        if pinnedConversationsContains(chat) {
            return
        }
        
        var chats = pinnedChats
        chats.append(chat)
        
        pinnedChats = chats
    }
    
    /// All pinned IMChats
    var pinnedChats: [IMChat] {
        get {
            self.pinnedConversationIdentifiers().compactMap {
                IMChatRegistry.shared.existingChat(withPinningIdentifier: $0)
            }
        }
        set {
            self.setPinnedChats(newValue, withUpdateReason: "contextMenu")
        }
    }
}
