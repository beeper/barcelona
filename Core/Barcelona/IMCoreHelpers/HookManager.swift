//
//  IMChatStatusChangeHinting.swift
//  Barcelona
//
//  Created by Eric Rabil on 7/26/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import IDS
import IMCore
import IMSharedUtilities
import IMFoundation
import InterposeKit
import Logging

private let log = Logger(label: "Hooks")

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
    try Interpose(IMHandle.self) {
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

private func IDSServiceHooks() throws -> Interpose {
    try Interpose(NSClassFromString("_IDSService")!) {
        try $0.prepareHook(Selector("_enforceSandboxPolicy")) {
            (store: TypedHook<@convention(c) (AnyObject, Selector) -> Void, @convention(block) (AnyObject) -> Void>) in
            { object in

            }
        }
    }
}

private func IDSQueryHooks() throws -> Interpose {
    let log = Logger(label: "IDSQueryHook")

    // Can't use the class itself since IDS.framework doesn't expose it to be linked against
    return try Interpose(NSClassFromString("_IDSIDQueryController")!) {
        try $0.prepareHook(#selector(_IDSIDQueryController.__sendMessage(_:queue:reply:failBlock:waitForReply:))) {
            (
                store: TypedHook<@convention (c) (
                    AnyObject,
                    Selector,
                    OS_xpc_object,
                    DispatchQueue,
                    @escaping (OS_xpc_object?) -> Void,
                    @escaping (NSError?) -> Void,
                    Bool
                ) -> Void,
                @convention(block) (
                    AnyObject, // _IDSIDQueryController; can't link against
                    OS_xpc_object, // the message we're sending
                    DispatchQueue, // the queue it's being sent on
                    @escaping @convention(block) (OS_xpc_object?) -> Void, // The block that gets called when it succeeds the xpc call
                    @escaping @convention(block) (NSError?) -> Void, // The block that gets called when it fails (not certain what 'failure' exactly is here)
                    Bool // if we want the request to be synchronous
                ) -> Void>
            ) in
            { controller, message, queue, replyBlock, failBlock, waitForReply  in
                let logReplyBlock: (OS_xpc_object?) -> Void = { [replyBlock] replyObject in
                    log.debug("Got reply for __sendMessage, is object: \(String(describing: replyObject))")
                    replyBlock(replyObject)
                }

                let logFailureBlock: (NSError?) -> Void = { [failBlock] error in
                    log.error("Got failure for __sendMessage, error is \(String(describing: error))")
                    failBlock(error)
                }

                store.original(controller, store.selector, message, queue, logReplyBlock, logFailureBlock, waitForReply)
            }
        }
    }
}

class HookManager {
    static let shared = HookManager()

    let hooks = [CNLogSilencerHooks, IMHandleHooks, IDSServiceHooks, IDSQueryHooks]
    private var appliedHooks: [Interpose]?

    func apply() throws {
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

    func revert() throws {
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
