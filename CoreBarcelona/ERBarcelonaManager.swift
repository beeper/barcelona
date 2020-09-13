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

@objc public class ERBarcelonaManager: NSObject {
    @objc class var isSimulation: Bool {
        IMCoreSimulatedEnvironmentEnabled()
    }
    
    @objc public class func bootstrap() {
        IMChatRegistry.shared._defaultNumberOfMessagesToLoad = isSimulation ? .max : 0
        
        var controller: IMDaemonController!
        
        if isSimulation {
            controller = IMSimulatedDaemonController.sharedInstance() as! IMSimulatedDaemonController
        } else {
            controller = IMDaemonController.sharedInstance()!
        }
        
        let _ = ERChatSubscriptionWatcher.shared
        
        #if canImport(UIKit)
        IMContactStore.sharedInstance()!.setValue(CNContactStore(), forKey: "_contactStore")
        #endif

        /** Registers with imagent */
        controller.listener.addHandler(ERDaemonListener.self.shared)
        controller.addListenerID("com.ericrabil.imessage-rest", capabilities: UInt32(18341))
        
        if isSimulation {
            ERIMSimulationTools.bootstrap()
            
            IMSimulatedDaemonController.beginSimulatingDaemon()
        }

        NSLog("Barcelona has been setup")
    }
    
    @objc public static let machServiceName = "com.ericrabil.imessage-rest"
}

@_cdecl("ERInitializeBarcelona")
public func ERInitializeBarcelona() {
    ERBarcelonaManager.bootstrap()
}
