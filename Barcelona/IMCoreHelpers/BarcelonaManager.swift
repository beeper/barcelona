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

private let log = OSLog(subsystem: "com.ericrabil.barcelona", category: "BarcelonaManager")

public let BLListenerIdentifier = "com.ericrabil.imessage-rest"
public let BLIsSimulation = IMCoreSimulatedEnvironmentEnabled()

@_cdecl("BLTeardownController")
public func BLTeardownController() {
    let controller = IMDaemonController.sharedInstance()
    
    controller.disconnectFromDaemon()
    controller.listener.removeHandler(ERDaemonListener.shared)
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

@_cdecl("BLBootstrapController")
public func BLBootstrapController() -> Bool {
    guard BLSwizzleDaemonController() else {
        return false
    }
    
    do {
        try HookManager.shared.apply()
    } catch {
        log.fault("Failed to apply hooks: %@", String(describing: error))
        return false
    }
    
    let controller = IMDaemonController.sharedInstance()
    
    #if canImport(UIKit)
    IMContactStore.sharedInstance()!.setValue(CNContactStore(), forKey: "_contactStore")
    #endif
    
    /** Registers with imagent */
    controller.listener.addHandler(ERDaemonListener.shared)
    
    DispatchQueue.main.schedule {
        log("Connecting to daemon...")
        
        controller.addListenerID(BLListenerIdentifier, capabilities: FZListenerCapabilities.defaults_)
        controller.blockUntilConnected()
        
        log("Connected!")
    }
    
    if BLIsSimulation {
        ERIMSimulationTools.bootstrap()
        
        IMSimulatedDaemonController.beginSimulatingDaemon()
    }
    
    return true
}

@_cdecl("BLExecuteOnceLoaded")
public func BLExecuteOnceLoaded(_ cb: @escaping () -> ()) {
    Promise(backing: ERChatRegistryDidLoadPublisher).whenSuccess(cb)
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
    
    public func bootstrap() -> Promise<Bool, Never> {
        guard BLBootstrapController() else {
            return .success(false)
        }
        
        return Promise(backing: NotificationCenter.default.publisher(for: .IMChatRegistryDidLoad)).then { _ in
            return true
        }
    }
}
