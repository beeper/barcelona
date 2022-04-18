//
//  BarcelonaManager.swift
//  Barcelona
//
//  Created by Eric Rabil on 7/24/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import InterposeKit
import BarcelonaFoundation
import OSLog
import IMCore
import IMDPersistence

private let log = Logger(category: "BarcelonaManager")

public let BLListenerIdentifier = "com.ericrabil.imessage-rest"
public let BLIsSimulation = IMCoreSimulatedEnvironmentEnabled()

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
        try [#selector(IMDaemonController.shared), #selector(IMDaemonController.sharedInstance)].forEach { sel in
            try (object_getClass(IMDaemonController.self) as! NSObject.Type).hook(
                sel,
                methodSignature: (@convention(c) (AnyObject, Selector) -> IMDaemonController).self) { store in
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
        log.fault("failed to swizzle daemon controller: %@", String(describing: error))
        return false
    }
}

public func BLSetup() -> Bool {
    do {
        try HookManager.shared.apply()
    } catch {
        log.fault("Failed to apply hooks: %@", String(describing: error))
        return false
    }
    
    let controller = IMDaemonController.sharedInstance()
    controller.listener.addHandler(CBDaemonListener.shared)
    
    log("Connecting to daemon...")
    
    controller.addListenerID(BLListenerIdentifier, capabilities: FZListenerCapabilities.defaults_)
    controller.blockUntilConnected()
    
    #if DEBUG
    log.debug("Connected to daemon. Fetching nicknames...")
    #endif
    
    controller.fetchNicknames()
    
    #if DEBUG
    log.debug("Fetched nicknames. Setting up IMContactStore...")
    #endif
    
    IMContactStore.sharedInstance().checkForContactStoreChanges()
    
    log("Connected.")
    
    ifDebugBuild {
        if CBFeatureFlags.scratchbox && !_scratchboxIsEmpty {
            _scratchboxMain()
            
            if CBFeatureFlags.exitAfterScratchbox {
                exit(0)
            }
        }
    }
    
    return true
}

public func BLTeardown() {
    let controller = IMDaemonController.sharedInstance()
    controller.listener.removeHandler(CBDaemonListener.shared)
    
    log("Disconnecting from daemon...")
    
    controller.disconnectFromDaemon()
}

@_cdecl("BLBootstrapController")
public func BLBootstrapController(_ callbackC: (@convention(c) (Bool) -> ())? = nil, _ callbackSwift: ((Bool) -> ())? = nil) -> Bool {
    guard BLSwizzleDaemonController() else {
        callbackC?(false)
        callbackSwift?(false)
        return false
    }
    
    // As long as we do single-threaded, READ-ONLY access to IMDPersistence, this is not an issue.
    // Again, please, I am BEGGING you, never use IMDPersistence for write operations.
    // Even if we were properly using it, we should only perform mutating operations using the IMCore apis to prevent corrupted state
    IMDSetIsRunningInDatabaseServerProcess(ProcessInfo.processInfo.arguments.contains("-imdaemon") ? 0x1 : 0x0)
    
    do {
        try HookManager.shared.apply()
    } catch {
        log.fault("Failed to apply hooks: %@", String(describing: error))
        return false
    }
    
    let controller = IMDaemonController.sharedInstance()
    
    /** Registers with imagent */
    controller.listener.addHandler(CBDaemonListener.shared)
    
    RunLoop.main.schedule {
        log("Connecting to daemon...")
        
        controller.addListenerID(BLListenerIdentifier, capabilities: FZListenerCapabilities.defaults_)
        controller.blockUntilConnected()
        
        #if DEBUG
        log.debug("Connected to daemon. Fetching nicknames...")
        #endif
        
        controller.fetchNicknames()
        
        #if DEBUG
        log.debug("Fetched nicknames. Setting up IMContactStore...")
        #endif
        
        IMContactStore.sharedInstance().checkForContactStoreChanges()
        
        log("Connected.")
        
        ifDebugBuild {
            if CBFeatureFlags.scratchbox && !_scratchboxIsEmpty {
                _scratchboxMain()
                
                if CBFeatureFlags.exitAfterScratchbox {
                    exit(0)
                }
            }
        }
    }
    
    if BLIsSimulation {
        ERIMSimulationTools.bootstrap()
        
        IMSimulatedDaemonController.beginSimulatingDaemon()
    }
    
    NotificationCenter.default.once(notificationNamed: .IMChatRegistryDidLoad).resolve(on: DispatchQueue.main).then { _ in
        CBDaemonListener.shared.startListening()
        
        callbackC?(true)
        callbackSwift?(true)
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
        Promise { resolve in
            guard BLBootstrapController(nil, resolve) else {
                return resolve(false)
            }
        }
    }
}
