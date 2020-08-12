//
//  DispatchSupervisor.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/9/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import os.log

private let log_dispatchSupervisor = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "DispatchSupervisor")

/**
 Tracks an array of dispatchers and wakes/sleeps them on command.
 */
class DispatchSupervisor: EventDispatcher {
    var awake: Bool = false {
        didSet {
            if awake {
                os_log("😳 Dispatch supervisor is awake", log_dispatchSupervisor)
            } else {
                os_log("😴 Dispatch supervisor is asleep.", log_dispatchSupervisor)
            }
        }
    }
    private var dispatchers: [EventDispatcher] = []
    
    func register(_ dispatcher: EventDispatcher.Type) {
        dispatchers.append(dispatcher.init(center: self.center))
    }
    
    override func sleep() {
        dispatchers.forEach { $0.sleep() }
        
        awake = false
    }
    
    override func wake() {
        if awake {
            return
        }
        
        dispatchers.forEach { $0.wake() }
        
        awake = true
    }
}
