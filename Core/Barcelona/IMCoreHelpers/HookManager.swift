//
//  IMChatStatusChangeHinting.swift
//  Barcelona
//
//  Created by Eric Rabil on 7/26/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import IMSharedUtilities
import InterposeKit
import Logging

private let log = Logger(label: "Hooks")

internal struct BLMessageStatusChange {
    let message: IMMessage
    let wasSent: Bool
    let wasDelivered: Bool
    let wasRead: Bool
}

private func CNLogSilencerHooks() throws -> Interpose? {
    try NSClassFromString("CNCDPersistenceMetrics").flatMap(object_getClass(_:))
        .map { cls in
            try Interpose(cls) {
                try $0.prepareHook(Selector("sendDidCreatePSCWithCountOfStores:countOfAccounts:")) {
                    (
                        store: TypedHook<
                            @convention(c) (AnyObject, Selector, Int, Int) -> Int,
                            @convention(block) (AnyObject, Int, Int) -> Int
                        >
                    ) in
                    { a, b, c in
                        1
                    }
                }
            }
        }
}

private let PNCopyBestGuessCountryCodeForNumber:
    (
        @convention(c) (CFString) -> Unmanaged<CFString>  // retained
    ) = CBWeakLink(
        against: .privateFramework(name: "CorePhoneNumbers"),
        .symbol("PNCopyBestGuessCountryCodeForNumber")
    )!

private func IMHandleHooks() throws -> Interpose {
    return try Interpose(IMHandle.self) {
        try $0.prepareHook(#selector(getter:IMHandle.countryCode)) {
            (
                store: TypedHook<
                    @convention(c) (AnyObject, Selector) -> String, @convention(block) (IMHandle) -> String
                >
            )
            in
            { handle in
                let id = handle.id

                guard id.isPhoneNumber else {
                    return store.original(handle, store.selector)
                }

                return (PNCopyBestGuessCountryCodeForNumber(id as CFString).takeRetainedValue() as String).uppercased()
            }
        }
    }
}

private func IMChatHooks() throws -> Interpose {
    try Interpose(IMChat.self) {
        try $0.prepareHook(#selector(IMChat._handleIncomingItem(_:))) {
            (
                store: TypedHook<
                    @convention(c) (AnyObject, Selector, AnyObject) -> Bool, @convention(block) (IMChat, IMItem) -> Bool
                >
            ) in
            { chat, item in
                let index = chat._index(of: item)

                let oldItem: IMItem? = index < chat._items.count ? chat._items[Int(index)] : nil

                if let message = item.message(), let oldMessage = oldItem?.message() {
                    let wasDelivered = message.isDelivered && !oldMessage.isDelivered
                    let wasRead = message.isRead && !oldMessage.isRead

                    if wasRead || wasDelivered {
                        let statusItem = IMMessageStatusChatItem()

                        if wasRead {
                            statusItem._init(
                                withItem: item,
                                statusType: StatusType.read.rawValue,
                                time: message.timeRead,
                                count: 1
                            )
                        } else {
                            statusItem._init(
                                withItem: item,
                                statusType: StatusType.delivered.rawValue,
                                time: message.timeDelivered,
                                count: 1
                            )
                        }

                        NotificationCenter.default.post(
                            name: BLMessageStatusChangedNotification,
                            object: StatusChatItem(item: statusItem, chatID: chat.chatIdentifier)
                        )

                        do {
                            let hook = try Interpose(NotificationCenter.self) {
                                try $0.prepareHook(#selector(NotificationCenter.post(name:object:userInfo:))) {
                                    (
                                        store: TypedHook<
                                            @convention(c) (AnyObject, Selector, AnyObject, AnyObject?, AnyObject?) ->
                                                Void,
                                            @convention(block) (AnyObject, AnyObject, AnyObject?, AnyObject?) -> Void
                                        >
                                    ) in
                                    { `self`, name, object, userInfo in

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
        try $0.prepareHook(Selector("_enforceSandboxPolicy")) {
            (store: TypedHook<@convention(c) (AnyObject, Selector) -> Void, @convention(block) (AnyObject) -> Void>) in
            { object in

            }
        }
    }
}

private func IMIDSHooks() throws -> Interpose {
    try Interpose(NSClassFromString("IDSIDQueryController")!) {
        try $0.prepareHook(Selector("_hasCacheForService:")) {
            (
                store: TypedHook<
                    @convention(c) (AnyObject, Selector, AnyObject) -> Bool, @convention(block) (AnyObject) -> CChar
                >
            ) in
            { _ in
                0
            }
        }
    }
}

public class HookManager {
    public static let shared = HookManager()

    let hooks = [IMChatHooks, IMIDSHooks, CNLogSilencerHooks, IMHandleHooks, IDSServiceHooks]
    private var appliedHooks: [Interpose]?

    public func apply() throws {
        try revert()

        #if DEBUG
        log.debug("Applying hooks")
        #endif

        appliedHooks = []

        for (index, hook) in hooks.enumerated() {
            #if DEBUG
            log.debug("Applying hook \(index + 1) of \(hooks.count)")
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
            log.debug("Reverting hook \(index + 1) of \(hooks.count)")
            #endif

            try hook.revert()
        }

        #if DEBUG
        log.debug("All hooks reverted")
        #endif
    }
}
