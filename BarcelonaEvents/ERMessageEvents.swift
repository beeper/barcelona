//
//  ERMessageEvents.swift
//  imessage-rest
//
//  Created by Eric Rabil on 8/12/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import Barcelona
import BarcelonaFoundation
import IMCore
import os.log

private let log_messageEvents = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "ERMessageEvents")

public class ERMessageEvents: EventDispatcher {
    public override func wake() {
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
        
        addObserver(forName: BLMessageStatusChangedNotification) {
            guard let item = $0.object as? StatusChatItem else {
                return
            }
            
            self.bus.dispatch(.itemStatusChanged(item))
        }
    }
    
    private func messagesDeleted(_ guids: [String]) {
        if guids.count == 0 {
            return
        }
        
        bus.dispatch(.itemsRemoved(guids))
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
        
        Promise.whenAllSucceed(items.compactMap { item -> Promise<ChatItem?, Error>? in
            if !ChangedItemsExclusion.contains(where: {
                item.isKind(of: $0)
            }) {
                return nil
            }
            
            if item is IMAssociatedMessageItem, item.isFromMe, !overrideFromMe {
                return nil
            }
            
            return itemGUIDAsChatItem(item.guid, in: chat.id)
        }).then {
            $0.compactMap { $0?.eraseToAnyChatItem() }
        }.whenSuccess {
            if $0.count == 0 { return }
            self.bus.dispatch(.itemsReceived($0))
        }
    }
    
    /** Counts as an update */
    private func messagesUpdated(_ items: [IMItem], inChat chatIdentifier: String) {
        let chat = IMChatRegistry.shared.existingChat(withChatIdentifier: chatIdentifier)!
        
        Promise.whenAllSucceed(items.map { item -> Promise<ChatItem?, Error> in
            return itemGUIDAsChatItem(item.guid, in: chat.id)
        }).map {
            $0.compactMap { $0?.eraseToAnyChatItem() }
        }.whenSuccess {
            if $0.count == 0 { return }
            self.bus.dispatch(.itemsUpdated($0))
        }
    }
    
    /** Counts as an update */
    private func messageUpdated(_ item: IMItem, inChat chatIdentifier: String) {
        messagesUpdated([item], inChat: chatIdentifier)
    }
    
    private func itemGUIDAsChatItem(_ guid: String, in chatID: String) -> Promise<ChatItem?, Error> {
        IMMessage.message(withGUID: guid)
    }
}
