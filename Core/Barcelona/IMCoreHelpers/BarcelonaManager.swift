//
//  BarcelonaManager.swift
//  Barcelona
//
//  Created by Eric Rabil on 7/24/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import BarcelonaFoundation
import Foundation
import IMCore
import IMDPersistence
import IMSharedUtilities
import InterposeKit
import Logging

private let log = Logger(label: "BarcelonaManager")

let BLListenerIdentifier = "com.ericrabil.imessage-rest"
let BLIsSimulation = IMCoreSimulatedEnvironmentEnabled()

@_cdecl("BLTeardownController")
public func BLTeardownController() {
    let controller = IMDaemonController.sharedInstance()

    controller.disconnectFromDaemon()
    controller.listener.removeHandler(CBDaemonListener.shared)
    controller.removeListenerID(BLListenerIdentifier)

    IMChatRegistry.shared.allChats
        .map(\.guid)
        .forEach(IMChatRegistry.shared._unregisterChat(withGUID:))

    IMFileTransferCenter.sharedInstance()._clearTransfers()
}

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

public func BLSetup() -> Bool {
    do {
        try HookManager.shared.apply()
    } catch {
        log.error("Failed to apply hooks: \(String(describing: error))")
        return false
    }

    let controller = IMDaemonController.sharedInstance()
    controller.listener.addHandler(CBDaemonListener.shared)

    log.info("Connecting to daemon...")

    controller.addListenerID(BLListenerIdentifier, capabilities: FZListenerCapabilities.defaults_)
    controller.blockUntilConnected()

    log.info("Connected.")

    return true
}

func BLTeardown() {
    let controller = IMDaemonController.sharedInstance()
    controller.listener.removeHandler(CBDaemonListener.shared)

    log.info("Disconnecting from daemon...")

    controller.disconnectFromDaemon()
}

@_cdecl("BLBootstrapController")
public func BLBootstrapController(
    _ callbackC: (@convention(c) (Bool) -> Void)? = nil,
    _ callbackSwift: (@Sendable (Bool) -> Void)? = nil
) -> Bool {
    guard BLSwizzleDaemonController() else {
        callbackC?(false)
        callbackSwift?(false)
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

    _ = CBFileTransferCenter.shared
    _ = CBChatRegistry.shared

    RunLoop.main.schedule {
        log.info("Connecting to daemon...")
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

    Task { @MainActor in
        log.info("Waiting for CBChatRegistry to load chats")
        await CBChatRegistry.shared.onLoadedChats {
            CBDaemonListener.shared.startListening()
            callbackC?(true)
            callbackSwift?(true)
            log.info("All systems go!")
        }
    }

    return true
}

public class BarcelonaManager {
    public static let shared = BarcelonaManager()

    public var daemonController: IMDaemonController {
        IMDaemonController.sharedInstance()
    }

    public func teardown() {
        BLTeardownController()
    }

    public func bootstrap() -> Bool {
        BLBootstrapController()
    }

    public func bootstrap() -> Promise<Bool> {
        let lifetime = BarcelonaManager.bootstrapTimeout
        return Promise<Bool> { resolve in
            guard BLBootstrapController(nil, resolve) else {
                return resolve(false)
            }
        }
        .resolve(on: RunLoop.main).withLifetime(lifetime: lifetime)
        .then { result in
            switch result {
            case .timedOut:
                throw BarcelonaError(code: 504, message: "Barcelona took more than \(lifetime)s to bootstrap")
            case .finished(let result):
                return result
            }
        }
    }
}

extension BarcelonaManager {
    public static var bootstrapTimeout: TimeInterval = 120
}
