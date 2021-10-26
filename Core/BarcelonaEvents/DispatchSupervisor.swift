//
//  DispatchSupervisor.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/9/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import BarcelonaFoundation

/**
 Tracks an array of dispatchers and wakes/sleeps them on command.
 */
public class DispatchSupervisor: EventDispatcher {
    var awake: Bool = false {
        didSet {
            if awake {
                CLInfo("DispatchSupervisor", "supervisor is awake")
            } else {
                CLInfo("DispatchSupervisor", "supervisor is asleep")
            }
        }
    }
    private var dispatchers: [EventDispatcher] = []
    
    public func register(_ dispatcher: EventDispatcher.Type) {
        dispatchers.append(dispatcher.init(center: self.center, bus: bus))
    }
    
    public override func sleep() {
        dispatchers.forEach { $0.sleep() }
        
        awake = false
    }
    
    public override func wake() {
        if awake {
            return
        }
        
        dispatchers.forEach { $0.wake() }
        
        awake = true
    }
}
