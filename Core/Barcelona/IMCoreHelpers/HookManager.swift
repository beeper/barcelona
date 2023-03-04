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

private func IDSServiceHooks() throws -> Interpose {
    try Interpose(NSClassFromString("_IDSService")!) {
        try $0.prepareHook(Selector("_enforceSandboxPolicy")) {
            (store: TypedHook<@convention(c) (AnyObject, Selector) -> Void, @convention(block) (AnyObject) -> Void>) in
            { object in

            }
        }
    }
}

class HookManager {
    static let shared = HookManager()

    let hooks = [CNLogSilencerHooks, IMHandleHooks, IDSServiceHooks]
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
