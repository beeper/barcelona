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
import Contacts
import IMSharedUtilities

private let log = Logger(category: "Hooks")

internal struct BLMessageStatusChange {
    let message: IMMessage
    let wasSent: Bool
    let wasDelivered: Bool
    let wasRead: Bool
}

private func CNLogSilencerHooks() throws -> Interpose? {
    try NSClassFromString("CNCDPersistenceMetrics").flatMap(object_getClass(_:)).map { cls in
        try Interpose(cls) {
            try $0.prepareHook(Selector("sendDidCreatePSCWithCountOfStores:countOfAccounts:")) { (store: TypedHook<@convention(c) (AnyObject, Selector, Int, Int) -> Int, @convention(block) (AnyObject, Int, Int) -> Int>) in
                { a,b,c in
                    1
                }
            }
        }
    }
}

private let PNCopyBestGuessCountryCodeForNumber: (
    @convention(c) (CFString) -> Unmanaged<CFString> // retained
) = CBWeakLink(against: .privateFramework(name: "CorePhoneNumbers"), .symbol("PNCopyBestGuessCountryCodeForNumber"))!

private func IMHandleRegistrarHooks() throws -> Interpose {
    return try Interpose(IMHandleRegistrar.self) {
        try $0.prepareHook(#selector(IMHandleRegistrar._handleDeleteContactChangeHistoryEvent(_:))) { (store: TypedHook<@convention(c) (AnyObject, Selector, AnyObject) -> Int, @convention(block) (IMHandleRegistrar, NSNotification) -> Int>) in
            { _self, notification in
                if let contactIdentifier = notification.userInfo?["__kIMCSChangeHistoryContactIdentifierKey"] as? String {
                    if let handleIDs = IMContactStore.sharedInstance().handleIDs(forCNID: contactIdentifier) as? [String] {
                        // emit the handle IDs whose information is being reset due to an address book change
                        CBDaemonListener.shared.resetHandlePipeline.send(handleIDs)
                    }
                }
                return store.original(_self, store.selector, notification)
            } as @convention(block) (IMHandleRegistrar, NSNotification) -> Int
        }
    }
}

private func IMHandleHooks() throws -> Interpose {
    return try Interpose(IMHandle.self) {
        try $0.prepareHook(#selector(getter: IMHandle.countryCode)) { (store: TypedHook<@convention(c) (AnyObject, Selector) -> String, @convention(block) (IMHandle) -> String>) in
            { handle in
                let id = handle.id
                
                guard id.isPhoneNumber else {
                    return store.original(handle, store.selector)
                }
                
                return (PNCopyBestGuessCountryCodeForNumber(id as CFString).takeRetainedValue() as String).uppercased()
            }
        }
        let contactLogging = Logger(category: "ContactFuzzing")
        
        try $0.prepareHook(#selector(getter: IMHandle.cnContact)) { (store: TypedHook<@convention(c) (AnyObject, Selector) -> CNContact, @convention(block) (IMHandle) -> CNContact>) in
            { handle in
                let id = handle.id, countryCode = handle.countryCode.lowercased()
                
                guard id.isPhoneNumber, CBFeatureFlags.ifNot(\.ignoresSameCountryCodeAssertion, countryCode == IMAccountController.shared.iMessageAccount?.countryCode, else: true) else {
                    return store.original(handle, store.selector)
                }
                
                let originalRetval = store.original(handle, store.selector)
                if originalRetval.value(forKey: "hasBeenPersisted") as? Bool == true {
                    return originalRetval
                }
                
                var contact: CNContact?
                
                if CBFeatureFlags.contactFuzzEnumerator {
                    contact = try? CNContact.contact(matchingHandleID: id, countryCode: countryCode)
                } else {
                    contact = try? IMContactStore.sharedInstance().contactStore.unifiedContacts(matching: CNContact.predicateForContacts(matchingHandleID: id, countryCode: countryCode), keysToFetch: IMContactStore.keysForCNContact() as! [CNKeyDescriptor]).first
                }
                
                if let contact = contact {
                    ifDebugBuild {
                        contactLogging.info("choosing \(contact.debugDescription) for fuzzing result against handleID \(id)")
                    }
                    
                    IMContactStore.sharedInstance().addContact(contact, withID: id)
                    handle.setValue(contact, forKey: "cnContact")
                    return contact
                }
                
                return store.original(handle, store.selector)
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

private func IDSServiceHooks() throws -> Interpose {
    try Interpose(NSClassFromString("_IDSService")!) {
        try $0.prepareHook(Selector("_enforceSandboxPolicy")) { (store: TypedHook<@convention(c) (AnyObject, Selector) -> Void, @convention(block) (AnyObject) -> ()>) in
            { object in
                
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

public class HookManager {
    public static let shared = HookManager()
    
    let hooks = [IMChatHooks, IMIDSHooks, CNLogSilencerHooks, IMHandleHooks, IDSServiceHooks, IMHandleRegistrarHooks]
    private var appliedHooks: [Interpose]?
    
    public func apply() throws {
        try revert()
        
        #if DEBUG
        log.debug("Applying hooks")
        #endif
        
        appliedHooks = []
        
        for (index, hook) in hooks.enumerated() {
            #if DEBUG
            log.debug("Applying hook %ld of %ld", index + 1, hooks.count)
            #endif
            
            if let interpose = try hook() {
                appliedHooks!.append(interpose)
            }
        }
        
        #if DEBUG
        log.debug("All hooks applied")
        #endif
    }
    
    public func revert() throws {
        guard let appliedHooks = appliedHooks else {
            return
        }
        
        #if DEBUG
        log.debug("Reverting hooks")
        #endif
        
        for (index, hook) in appliedHooks.enumerated() {
            #if DEBUG
            log.debug("Reverting hook %ld of %ld", index + 1, hooks.count)
            #endif
            
            try hook.revert()
        }
        
        #if DEBUG
        log.debug("All hooks reverted")
        #endif
    }
}
