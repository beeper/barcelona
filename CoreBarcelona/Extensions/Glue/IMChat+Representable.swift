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
        
        let newSet = self.mutablePinnedConversationIdentifierSet
        newSet.remove(chat.pinningIdentifier!)
        
        self.mutablePinnedConversationIdentifierSet = newSet
    }
    
    func pin(chat: IMChat) {
        if pinnedConversationsContains(chat) {
            return
        }
        
        let newSet = self.mutablePinnedConversationIdentifierSet
        newSet.add(chat.pinningIdentifier!)
        
        self.mutablePinnedConversationIdentifierSet = newSet
    }
    
    private var mutablePinnedConversationIdentifierSet: NSMutableOrderedSet {
        get {
            NSMutableOrderedSet(orderedSet: pinnedConversationIdentifierSet)
        }
        set {
            #if os(macOS)
            self.setPinnedChats(IMChat.resolve(withIdentifiers: newValue.array.compactMap { $0 as? String }), withUpdateReason: "we in this bitch")
            #else
            self.setPinnedConversationIdentifiers(newValue)
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
