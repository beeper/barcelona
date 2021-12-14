//
//  IMChatStatusChangeHinting.swift
//  Barcelona
//
//  Created by Eric Rabil on 7/26/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import InterposeKit
import IMCore
import OSLog

private let log = Logger(category: "Hooks")

internal struct BLMessageStatusChange {
    let message: IMMessage
    let wasSent: Bool
    let wasDelivered: Bool
    let wasRead: Bool
}

private func CNLogSilencerHooks() throws -> Interpose {
    try Interpose(object_getClass(NSClassFromString("CNCDPersistenceMetrics")!)!) {
        try $0.prepareHook(Selector("sendDidCreatePSCWithCountOfStores:countOfAccounts:")) { (store: TypedHook<@convention(c) (AnyObject, Selector, Int, Int) -> Int, @convention(block) (AnyObject, Int, Int) -> Int>) in
            { a,b,c in
                1
            }
        }
    }
}

private func IMChatHooks() throws -> Interpose {
    try Interpose(IMChat.self) {
        try $0.prepareHook(#selector(IMChat._handleIncomingItem(_:))) { (store: TypedHook<@convention(c) (AnyObject, Selector, AnyObject) -> Bool, @convention(block) (IMChat, IMItem) -> Bool>) in
            { chat, item in
                let index = chat._index(of: item)
                
                let oldItem: IMItem? = index < chat._items.count ? chat._items[Int(index)] : nil
                
                if let message = item.message(), let oldMessage = oldItem?.message() {
                    let wasDelivered = message.isDelivered && !oldMessage.isDelivered
                    let wasRead = message.isRead && !oldMessage.isRead
                    
                    if wasRead || wasDelivered {
                        let statusItem = IMMessageStatusChatItem()
                        
                        if wasRead {
                            statusItem._init(withItem: item, statusType: StatusType.read.rawValue, time: message.timeRead, count: 1)
                        } else {
                            statusItem._init(withItem: item, statusType: StatusType.delivered.rawValue, time: message.timeDelivered, count: 1)
                        }
                        
                        NotificationCenter.default.post(name: BLMessageStatusChangedNotification, object: StatusChatItem(item: statusItem, chatID: chat.id))
                        
                        do {
                            let hook = try Interpose(NotificationCenter.self) {
                                try $0.prepareHook(#selector(NotificationCenter.post(name:object:userInfo:))) {
                                    (store: TypedHook<@convention(c) (AnyObject, Selector, AnyObject, AnyObject?, AnyObject?) -> Void, @convention(block) (AnyObject, AnyObject, AnyObject?, AnyObject?) -> Void>) in { `self`, name, object, userInfo in
                                        
                                    }
                                }
                            }
                            
                            let result = store.original(chat, store.selector, item)
                            
                            try hook.revert()
                            
                            return result
                        } catch {
                            fatalError(error.localizedDescription)
                        }
                    }
                }
                
                return store.original(chat, store.selector, item)
            }
        }
    }
}

private func IMIDSHooks() throws -> Interpose {
    try Interpose(NSClassFromString("IDSIDQueryController")!) {
        try $0.prepareHook(Selector("_hasCacheForService:")) { (store: TypedHook<@convention(c) (AnyObject, Selector, AnyObject) -> Bool, @convention(block) (AnyObject) -> CChar>) in { _ in
            0
        }}
    }
}

class HookManager {
    static let shared = HookManager()
    
    let hooks = [IMChatHooks, IMIDSHooks, CNLogSilencerHooks]
    private var appliedHooks: [Interpose]?
    
    func apply() throws {
        try revert()
        
        log.debug("Applying hooks")
        
        appliedHooks = []
        
        for (index, hook) in hooks.enumerated() {
            log.debug("Applying hook %ld of %ld", index + 1, hooks.count)
            
            appliedHooks!.append(try hook())
        }
        
        log.debug("All hooks applied")
    }
    
    func revert() throws {
        guard let appliedHooks = appliedHooks else {
            return
        }
        
        log.debug("Reverting hooks")
        
        for (index, hook) in appliedHooks.enumerated() {
            log.debug("Reverting hook %ld of %ld", index + 1, hooks.count)
            
            try hook.revert()
        }
        
        log.debug("All hooks reverted")
    }
}
