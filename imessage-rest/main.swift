//
//  main.swift
//  imessage-rest
//
//  Created by Eric Rabil on 8/11/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Contacts
import Foundation
import IMCore
import Vapor

let controller = IMDaemonController.sharedInstance()!
let _ = ERChatSubscriptionWatcher.shared

controller.listener.addHandler(ERDaemonListener.self.shared)
controller.addListenerID("com.ericrabil.imessage-rest", capabilities: UInt32(18341))

let http = ERHTTPServer()

try! http.start()

NSLog("Message XPC Service has started")

let listener = NSXPCListener(machServiceName: kServiceName)
let listenerDelegate = ListenerDelegate()

listener.delegate = listenerDelegate

listener.resume()

RunLoop.current.run()
