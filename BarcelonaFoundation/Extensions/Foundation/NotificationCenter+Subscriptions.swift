//
//  NotificationCenter+Subscriptions.swift
//  BarcelonaFoundation
//
//  Created by Eric Rabil on 8/10/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation

public protocol NotificationSubscription {
    func unsubscribe() -> Void
}

public class SingleNotificationSubscription: NotificationSubscription {
    private var observer: NSObjectProtocol! {
        didSet {
            guard oldValue == nil else {
                preconditionFailure("observer can only be written to once")
            }
        }
    }
    
    public let center: NotificationCenter
    
    public init(center: NotificationCenter, name: NSNotification.Name?, object: Any?, queue: OperationQueue?, handler: @escaping (Notification, NotificationSubscription) -> ()) {
        self.center = center
        self.observer = center.addObserver(forName: name, object: object, queue: queue, using: { handler($0, self) })
    }
    
    fileprivate init(center: NotificationCenter, observer: NSObjectProtocol) {
        self.center = center
        self.observer = observer
    }
    
    public func unsubscribe() {
        center.removeObserver(observer!)
    }
}

public class ManyNotificationSubscription: NotificationSubscription {
    private var subscriptions: [NotificationSubscription] = []
    public let center: NotificationCenter
    
    public typealias PackedNotification = (name: NSNotification.Name?, object: Any?, queue: OperationQueue?)
    
    public init(center: NotificationCenter, notifications: [PackedNotification], handler: @escaping (Notification, NotificationSubscription) -> ()) {
        self.center = center
        self.subscriptions = notifications.map { name, object, queue in
            SingleNotificationSubscription(center: center, observer: center.addObserver(forName: name, object: object, queue: queue, using: { handler($0, self) }))
        }
    }
    
    public func unsubscribe() {
        subscriptions.forEach {
            $0.unsubscribe()
        }
    }
}

public extension NotificationCenter {
    @discardableResult
    func subscribe(toNotificationNamed name: NSNotification.Name? = nil, object: Any? = nil, queue: OperationQueue? = nil, using block: @escaping (Notification, NotificationSubscription) -> ()) -> NotificationSubscription {
        SingleNotificationSubscription(center: self, name: name, object: object, queue: queue, handler: block)
    }
    
    @discardableResult
    func subscribe(toNotificationsNamed names: [NSNotification.Name], using block: @escaping (Notification, NotificationSubscription) -> ()) -> NotificationSubscription {
        ManyNotificationSubscription(center: self, notifications: names.map { (name: $0, object: nil, queue: nil) }, handler: block)
    }
    
    @discardableResult
    func subscribe(toNotificationsNamed names: [String], using block: @escaping (Notification, NotificationSubscription) -> ()) -> NotificationSubscription {
        ManyNotificationSubscription(center: self, notifications: names.map { (name: .init($0), object: nil, queue: nil) }, handler: block)
    }
    
    @discardableResult
    func subscribe(toNotifications notifications: [ManyNotificationSubscription.PackedNotification], using block: @escaping (Notification, NotificationSubscription) -> ()) -> NotificationSubscription {
        ManyNotificationSubscription(center: self, notifications: notifications, handler: block)
    }
}
