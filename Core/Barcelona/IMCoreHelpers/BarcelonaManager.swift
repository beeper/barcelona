//
//  BarcelonaManager.swift
//  Barcelona
//
//  Created by Eric Rabil on 7/24/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import IMDPersistence
import IMSharedUtilities
import InterposeKit
import Logging
import notify

private let log = Logger(label: "BarcelonaManager")

let BLListenerIdentifier = "com.ericrabil.imessage-rest"
let BLIsSimulation = IMCoreSimulatedEnvironmentEnabled()

@_cdecl("BLSwizzleDaemonController")
func BLSwizzleDaemonController() -> Bool {
    do {
        try [#selector(IMDaemonController.shared), #selector(IMDaemonController.sharedInstance)]
            .forEach { sel in
                try (object_getClass(IMDaemonController.self) as! NSObject.Type)
                    .hook(
                        sel,
                        methodSignature: (@convention(c) (AnyObject, Selector) -> IMDaemonController).self
                    ) { store in
                        return { `self` in
                            if BLIsSimulation {
                                return IMSimulatedDaemonController.sharedInstance()
                            } else {
                                return store.original(`self`, store.selector)
                            }
                        } as (@convention(block) (AnyObject) -> IMDaemonController)
                    }
            }

        return true
    } catch {
        log.error("failed to swizzle daemon controller: \(String(describing: error))")
        return false
    }
}

func BLBootstrapController(chatRegistry: CBChatRegistry) async -> Bool {
    guard BLSwizzleDaemonController() else {
        return false
    }

    // This is called with imagentd but, just to make sure that it's all good when we're running barcelona, call it here as well
    typealias CObjcBoolToVoid = @convention(c) (ObjCBool) -> Void
    if let _IMLogForceWriteToStdout: CObjcBoolToVoid = CBWeakLink(
        against: .privateFramework(name: "IMFoundation"),
        .init(constraints: [], symbol: "_IMLogForceWriteToStdout")
    ) {
        _IMLogForceWriteToStdout(true)
    }
    if let _IMLogForceEnableEverything: CObjcBoolToVoid = CBWeakLink(
        against: .privateFramework(name: "IMFoundation"),
        .init(constraints: [], symbol: "_IMLogForceEnableEverything")
    ) {
        _IMLogForceEnableEverything(true)
    }

    // As long as we do single-threaded, READ-ONLY access to IMDPersistence, this is not an issue.
    // Again, please, I am BEGGING you, never use IMDPersistence for write operations.
    // Even if we were properly using it, we should only perform mutating operations using the IMCore apis to prevent corrupted state
    IMDSetIsRunningInDatabaseServerProcess(ProcessInfo.processInfo.arguments.contains("-imdaemon") ? 0x1 : 0x0)

    do {
        try HookManager.shared.apply()
    } catch {
        log.error("Failed to apply hooks: \(String(describing: error))")
        return false
    }

    let controller = IMDaemonController.sharedInstance()

    /** Registers with imagent */
    controller.listener.addHandler(CBDaemonListener.shared)

    RunLoop.main.schedule {
        log.info("BLBootstrapController Connecting to daemon...")
        controller.addListenerID(BLListenerIdentifier, capabilities: FZListenerCapabilities.defaults_)
        controller.blockUntilConnected()
        log.info("Connected to daemon.")

        #if DEBUG
        log.debug("Set up IMContactStore. Loading correlation controller...")
        #endif

        // CBSenderCorrelationController's usage of Pwomise creates data races (according to the thread sanitizer)
        // and we don't use it anymore, so let's just make sure it's never called so that we don't get those data races.
        // Also, once I commented this out, I was able to debug async functions (whereas previously breakpoints in some
        // top-level async functions would never catch, but if we never call the controller, they do catch)
        // _ = CBSenderCorrelationController.shared

        sleep(1)

        #if DEBUG
        log.debug("Loaded correlation controller. Loading all chats...")
        #endif

        if #available(macOS 12, *) {
            controller.loadAllChats()
        } else {
            controller.loadChats(withChatID: "all")
        }

        for account in IMAccountController.shared.accounts {
            // We want to make sure that nothing is prohibited us
            account.updateCapabilities(UInt64.max)
        }
    }

    if BLIsSimulation {
        ERIMSimulationTools.bootstrap()

        IMSimulatedDaemonController.beginSimulatingDaemon()
    }

    log.info("Adding callback for CBChatRegistry to load chats")
    await chatRegistry.onLoadedChats {
        await CBDaemonListener.shared.startListening()
        log.info("All systems go!")
    }

    return true
}

public class BarcelonaManager {
    public static let shared = BarcelonaManager()

    @MainActor public func bootstrap(chatRegistry: CBChatRegistry) async throws -> Bool {
        do {
            return try await Task(timeout: Self.bootstrapTimeout) {
                await BLBootstrapController(chatRegistry: chatRegistry)
            }.value
        } catch {
            throw BarcelonaError(code: 504, message: "Barcelona took more than \(Self.bootstrapTimeout)s to bootstrap")
        }
    }
}

extension BarcelonaManager {
    public static var bootstrapTimeout: TimeInterval = 120
}
