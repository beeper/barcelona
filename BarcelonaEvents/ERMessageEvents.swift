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

internal class ThinDebouncer {
    fileprivate var timers: [Int: DispatchWorkItem] = [:]
    
    static let shared = ThinDebouncer()
}

internal extension ThinDebouncer {
    @_optimize(speed)
    @_transparent
    func submit(hash: Int, delay: DispatchTimeInterval, cb: @escaping () -> ()) {
        timers[hash]?.cancel()
        timers[hash] = DispatchWorkItem(block: cb)
        EventBus.queue.asyncAfter(deadline: .now().advanced(by: delay), execute: timers[hash]!)
    }
    
    @_optimize(speed)
    @_transparent
    func submit<P: RawRepresentable>(space: P, tag: String, delay: DispatchTimeInterval, cb: @escaping () -> ()) where P.RawValue == String {
        submit(hash: (space.rawValue + tag).hash, delay: delay, cb: cb)
    }
}

public class ERMessageEvents: EventDispatcher {
    override var log: Logger { Logger(category: "ERMessageEvents") }
    
    public override func wake() {
        addObserver(forName: ERChatMessageReceivedNotification) {
            guard let item = $0.object as? IMItem, let chat = ($0.userInfo as? [String: Any])?["chat"] as? String else {
                return
            }

            ThinDebouncer.shared.submit(space: $0.name, tag: item.id, delay: .milliseconds(2)) {
                self.messageReceived(item, inChat: chat)
            }
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
        addObserver(forName: BLChatMessageSentNotification) {
            guard let userInfo = $0.userInfo as? [String: Any], let chat = userInfo["chat"] as? String, let item = userInfo["item"] as? IMMessageItem else {
                return
            }
            
            ThinDebouncer.shared.submit(space: $0.name, tag: item.id, delay: .milliseconds(2)) {
                self.messagesReceived([item], inChat: chat, overrideFromMe: true)
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
            
            ThinDebouncer.shared.submit(space: $0.name, tag: item.id, delay: .milliseconds(2)) {
                self.messageUpdated(item, inChat: chat)
            }
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
        BLLoadChatItems(withGUIDs: items.map(\.guid), chatID: chatIdentifier).map {
            $0.eraseToAnyChatItem()
        }.then {
            if $0.count != items.count {
                self.log.warn("started with %d items, but ended with 0 items!", items.count)
            }
            
            if $0.count == 0 {
                self.log.warn("no-op for no loaded items")
                return
            }
            
            self.bus.dispatch(.itemsReceived($0))
        }
    }
    
    /** Counts as an update */
    private func messagesUpdated(_ items: [IMItem], inChat chatIdentifier: String) {
        BLLoadChatItems(withGUIDs: items.map(\.guid), chatID: chatIdentifier).map {
            $0.eraseToAnyChatItem()
        }.then {
            if $0.count == 0 { return }
            self.bus.dispatch(.itemsUpdated($0))
        }
    }
    
    /** Counts as an update */
    private func messageUpdated(_ item: IMItem, inChat chatIdentifier: String) {
        messagesUpdated([item], inChat: chatIdentifier)
    }
}
