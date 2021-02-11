//
//  IMChat+Representable.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/9/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

@available(iOS 14, macOS 10.16, watchOS 7, *)
extension IMPinnedConversationsController {
    func unpin(chat: IMChat) {
        if !pinnedConversationsContains(chat) {
            return
        }
        
        pinnedChats = pinnedChats.filter {
            $0.pinningIdentifier != chat.pinningIdentifier
        }
    }
    
    func pin(chat: IMChat) {
        if pinnedConversationsContains(chat) {
            return
        }
        
        var chats = pinnedChats
        chats.append(chat)
        
        pinnedChats = chats
    }
    
    private var pinnedChats: [IMChat] {
        get {
            self.pinnedConversationIdentifiers().compactMap {
                IMChatRegistry.shared.existingChat(withPinningIdentifier: $0)
            }
        }
        set {
            #if os(macOS)
            self.setPinnedChats(newValue, withUpdateReason: "we in this bitch")
            #else
            self.setPinnedConversationIdentifiers(NSOrderedSet(array: newValue.map {
                $0.pinningIdentifier
            }))
            #endif
        }
    }
}

public extension IMChat {
    var representation: Chat {
        Chat(self)
    }
    
    var readReceipts: Bool {
        get {
            value(forChatProperty: "EnableReadReceiptForChat") as? Bool ?? false
        }
        set {
            setValue(newValue == true ? 1 : 0, forChatProperty: "EnableReadReceiptForChat")
        }
    }
    
    var ignoreAlerts: Bool {
        get {
            value(forChatProperty: "ignoreAlertsFlag") as? Bool ?? false
        }
        set {
            setValue(newValue == true ? 1 : 0, forChatProperty: "ignoreAlertsFlag")
        }
    }
    
    var pinned: Bool {
        get {
            if #available(iOS 14, macOS 10.16, watchOS 7, *) {
                return isPinned
            } else {
                return false
            }
        }
        set {
            if newValue == pinned {
                return
            }
            if #available(iOS 14, macOS 10.16, watchOS 7, *) {
                newValue ? IMPinnedConversationsController.sharedInstance().pin(chat: self) : IMPinnedConversationsController.sharedInstance().unpin(chat: self)
            }
        }
    }
    
    var properties: ChatConfigurationRepresentation {
        ChatConfigurationRepresentation(id: id, readReceipts: readReceipts, ignoreAlerts: ignoreAlerts, pinned: pinned)
    }
    
    var representableParticipantIDs: BulkHandleIDRepresentation {
        BulkHandleIDRepresentation(handles: participantHandleIDs())
    }
}
