//
//  main.swift
//  imessage-rest
//
//  Created by Eric Rabil on 8/11/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import IMCore
import Contacts
import Foundation
import os.log

private var isRunning: Bool = false
private var didSwizzle: Bool = false
private var currentDaemonController: IMDaemonController? = nil

/// Manages the connection with IMAgent
@objc public class ERBarcelonaManager: NSObject {
    /// Whether we are running in a simulated environment
    @objc class var isSimulation: Bool {
        IMCoreSimulatedEnvironmentEnabled()
    }
    
    /// The daemon controller for the current environment
    private class var controller: IMDaemonController {
        if isSimulation {
            return IMSimulatedDaemonController.sharedInstance() as! IMSimulatedDaemonController
        } else {
            return IMDaemonController.sharedInstance()!
        }
    }
    
    /// Clears out the daemon controller
    private class func resetController() {
        if isSimulation {
            return
        }
        
        currentDaemonController = nil
    }
    
    /// Returns the daemon controller to use when interacting with imagent
    /// - Returns: daemon controller
    @objc public class func sharedDaemonController() -> IMDaemonController {
        if IMCoreSimulatedEnvironmentEnabled() {
            return IMSimulatedDaemonController.shared()
        }
        
        if currentDaemonController == nil {
            currentDaemonController = .init()
        }
        
        return currentDaemonController!
    }
    
    /// The bundle identifier used for iChat
    @objc public class func iChatBundleIdentifier() -> String {
        return "com.apple.iChat"
    }
    
    /// Points IMDaemonController.sharedInstance ro ERBarcelonaManager.sharedDaemonController
    @objc private class func swizzleDaemonControllerSharedInstance() {
        didSwizzle = true
        
        if isSimulation {
            return
        }
        
        let originalSelector = #selector(IMDaemonController.sharedInstance)
        let newSelector = #selector(ERBarcelonaManager.sharedDaemonController)
        
        let originalMethod = class_getClassMethod(IMDaemonController.self, originalSelector)!
        let newMethod = class_getClassMethod(ERBarcelonaManager.self, newSelector)!
        
        method_exchangeImplementations(originalMethod, newMethod)
    }
    
    @objc private static var observer: NSObjectProtocol?
    
    /// Tears down the IMCore state
    @objc public class func teardown() {
        if !isRunning {
            os_log("ERBarcelonaManager.teardown called while offline, discarding", type: .error)
            return
        }
        
        controller.disconnectFromDaemon()
        
        controller.listener.removeHandler(ERDaemonListener.shared)
        controller.removeListenerID("com.ericrabil.imessage-rest")
        
        IMChatRegistry.shared.allChats.forEach {
            IMChatRegistry.shared._unregisterChat(withGUID: $0.guid)
        }
        
        IMFileTransferCenter.sharedInstance()._clearTransfers()
        
        resetController()
        
        try! messageQuerySystem.syncShutdownGracefully()
        try! ingestorEventLoop.syncShutdownGracefully()
        try! databaseEventLoopGroup.syncShutdownGracefully()
        
        isRunning = false
    }
    
    /// Bootstraps the IMCore state
    @objc public class func bootstrap() {
        if !didSwizzle {
            swizzleDaemonControllerSharedInstance()
        }
        
        if isRunning {
            os_log("ERBarcelonaManager.bootstrap called while running, discarding", type: .error)
            return
        }
        
        isRunning = true
        
        IMChatRegistry.shared._defaultNumberOfMessagesToLoad = isSimulation ? .max : CHAT_CAPACITY
        
        let _ = ERChatSubscriptionWatcher.shared
        
        #if canImport(UIKit)
        IMContactStore.sharedInstance()!.setValue(CNContactStore(), forKey: "_contactStore")
        #endif

        /** Registers with imagent */
        controller.listener.addHandler(ERDaemonListener.shared)
        controller.addListenerID("com.ericrabil.imessage-rest", capabilities: UInt32(18341))
        
        if isSimulation {
            ERIMSimulationTools.bootstrap()
            
            IMSimulatedDaemonController.beginSimulatingDaemon()
        }
    }
    
    /// Bootstraps the IMCore state, executing a callback once completed
    /// - Parameter completion: completion callback
    @objc public class func bootstrap(completion: @escaping (Error?) -> ()) {
        if isRunning {
            os_log("ERBarcelonaManager.bootstrap called while running, discarding", type: .error)
            completion(BarcelonaError(code: 500, message: "Cannot call bootstrap while running"))
            return
        }
        
        self.bootstrap()
        
        observer = NotificationCenter.default.addObserver(forName: ERChatRegistryDidLoadNotification, object: nil, queue: .main, using: { _ in
            completion(nil)
            
            os_log("Got ERChatRegistryDidLoadNotification, calling back bootstrap observer!")
            
            if let observer = self.observer {
                NotificationCenter.default.removeObserver(observer)
            }
        })
    }
    
    @objc public static let machServiceName = "com.ericrabil.imessage-rest"
}

@_cdecl("ERInitializeBarcelona")
public func ERInitializeBarcelona() {
    ERBarcelonaManager.bootstrap()
}
