//
//  EventDispatcher.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/9/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation

private extension OperationQueue {
    convenience init(underlyingQueue: DispatchQueue) {
        self.init()
        self.underlyingQueue = underlyingQueue
    }
}

/**
 Base class for all event trackers. Manages the registration/deregistration of events.
 */
public class EventDispatcher {
    public required init(center: NotificationCenter, bus: EventBus) {
        self.center = center
        self.bus = bus
    }

    internal var center: NotificationCenter
    public let bus: EventBus
    private var observers: [NSObjectProtocol] = []
    
    /**
     Called when the process is going to sleep. Unbinds from notifications.
     */
    public func sleep() {
        observers.forEach {
            center.removeObserver($0)
        }
        
        observers = []
    }
    
    /**
     Called when the process is woken up. To be called by subclasses.
     */
    public func wake() {
        fatalError("EventDispatcher.wake() must be implemented by subclasses.")
    }
    
    internal func addObserver(forName name: Notification.Name, using block: @escaping (Notification) -> Void) {
        observers.append(center.addObserver(forName: name, object: nil, queue: OperationQueue(underlyingQueue: bus.queue), using: block))
    }
}
