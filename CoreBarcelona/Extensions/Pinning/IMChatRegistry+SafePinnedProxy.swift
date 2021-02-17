//
//  IMChatRegistry+SafePinnedProxy.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 2/13/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import IMCore

public extension IMChatRegistry {
    var pinnedChats: [IMChat] {
        get {
            if #available(iOS 14, macOS 10.16, watchOS 7, *) {
                return IMPinnedConversationsController.sharedInstance().pinnedChats
            }
            return []
        }
        set {
            if #available(iOS 14, macOS 10.16, watchOS 7, *) {
                IMPinnedConversationsController.sharedInstance().pinnedChats = newValue
            }
        }
    }
    
    var pinnedChatIdentifiers: [String] {
        get {
            pinnedChats.map {
                $0.id
            }
        }
        set {
            pinnedChats = IMChat.resolve(withIdentifiers: newValue)
        }
    }
}
