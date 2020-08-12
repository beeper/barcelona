//
//  EventDispatcher.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/9/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation

class EventDispatcher {
    required init(center: NotificationCenter) {
        self.center = center
    }

    internal var center: NotificationCenter
    private var observers: [NSObjectProtocol] = []
    
    /**
     Called when the process is going to sleep. Unbinds from notifications.
     */
    func sleep() {
        observers.forEach {
            center.removeObserver($0)
        }
        
        observers = []
    }
    
    /**
     Called when the process is woken up. To be called by subclasses.
     */
    func wake() {
        fatalError("EventDispatcher.wake() must be implemented by subclasses.")
    }
    
    internal func addObserver(forName name: Notification.Name, using block: @escaping (Notification) -> Void) {
        observers.append(center.addObserver(forName: name, object: nil, queue: .main, using: block))
    }
}
