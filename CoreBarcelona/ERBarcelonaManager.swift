//
//  main.swift
//  imessage-rest
//
//  Created by Eric Rabil on 8/11/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import IMCore
import Foundation

@objc public class ERBarcelonaManager: NSObject {
    @objc public class func bootstrap() {
        IMChatRegistry.shared._defaultNumberOfMessagesToLoad = 0
        
        let controller = IMDaemonController.sharedInstance()!
        let _ = ERChatSubscriptionWatcher.shared

        /** Registers with imagent */
        controller.listener.addHandler(ERDaemonListener.self.shared)
        controller.addListenerID("com.ericrabil.imessage-rest", capabilities: UInt32(18341))

        /** Sets up ChatItem serialization table */
        ChatItem.setup()

        NSLog("Barcelona has been setup")
    }
    
    @objc public static let machServiceName = "com.ericrabil.imessage-rest"
}
