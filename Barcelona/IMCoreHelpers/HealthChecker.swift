//
//  HealthChecker.swift
//  Barcelona
//
//  Created by Eric Rabil on 8/9/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import IMSharedUtilities
import IMFoundation

public extension Notification.Name {
    static let HealthCheckerStatusDidChange = Notification.Name("BarcelonaHealthCheckerStatusDidChangeNotification")
}

public class HealthChecker {
    public enum AuthenticationState: String, Codable, Hashable {
        public static let notifications: [NSNotification.Name] = [
            .IMAccountActivated, .IMAccountDeactivated, .IMAccountLoggedIn, .IMAccountLoggedOut, .IMAccountStatusChanged, .IMAccountLoginStatusChanged, .IMAccountRegistrationStatusChanged, .IMAccountProfileValidationStatusChanged, .IMServiceDidDisconnect, .IMServiceDidConnect
        ]
        
        case none
        case authenticated
        case registrationFailure
        case validationFaliure
        case signedOut
        
        public var error: String? {
            switch self {
            case .none:
                return "im-unconfigured"
            case .authenticated:
                return nil
            case .registrationFailure:
                return "im-registration-failure"
            case .validationFaliure:
                return "im-validation-failure"
            case .signedOut:
                return "im-signed-out"
            }
        }
        
        public var message: String? {
            switch self {
            case .none:
                return "No account has been signed in before."
            case .authenticated:
                return nil
            case .registrationFailure:
                return "Failed to register with the iMessage server."
            case .validationFaliure:
                return "Failed to validate iMessage aliases."
            case .signedOut:
                return "You have been signed out."
            }
        }
    }
    
    public enum ConnectionState: String, Codable, Hashable {
        public static let notifications: [NSNotification.Name] = AuthenticationState.notifications + [.IMDaemonDidConnect, .IMDaemonDidDisconnect]
        
        case connected
        case errored
        case offline
        case transientDisconnect
        
        public var error: String? {
            switch self {
            case .connected:
                return nil
            case .errored:
                return "im-unknown-error"
            case .offline:
                return "im-offline"
            case .transientDisconnect:
                return "im-transient-disconnect"
            }
        }
        
        public var message: String? {
            switch self {
            case .connected:
                return nil
            case .errored:
                return "An unknown error has occurred."
            case .offline:
                return "This account has been deactivated."
            case .transientDisconnect:
                return "Unable to connect to iMessage. Reconnecting soon."
            }
        }
    }
    
    public static let shared = HealthChecker()
    
    private var subscription: NotificationSubscription!
    
    private var lastHash: Int = 0 {
        didSet {
            if oldValue != lastHash {
                dispatch()
            }
        }
    }
    
    private init() {
        subscription = NotificationCenter.default.subscribe(toNotificationsNamed: ConnectionState.notifications) { _ in
            self.recomputeHash()
        }
    }
    
    private func recomputeHash() {
        var hasher = Hasher()
        authenticationState.hash(into: &hasher)
        connectionState.hash(into: &hasher)
        lastHash = hasher.finalize()
    }
    
    public var authenticationState: AuthenticationState {
        guard let account = IMAccountController.sharedInstance().activeIMessageAccount else {
            return .none
        }
        
        if account.registrationFailureReason != -1 {
            return .registrationFailure
        }
        
        if account.profileValidationErrorReason() != -1 {
            return .validationFaliure
        }
        
        if account.isActive {
            return .authenticated
        } else {
            return .signedOut
        }
    }
    
    public var connectionState: ConnectionState {
        if !IMDaemonController.shared().isConnected {
            return .transientDisconnect
        }
        
        switch authenticationState {
        case .none:
            return .offline
        case .signedOut:
            return .offline
        case .registrationFailure:
            return .errored
        case .validationFaliure:
            return .errored
        case .authenticated:
            let account = IMAccountController.sharedInstance().activeIMessageAccount!
            
            if !account.isConnected {
                return .offline
            }
            
            return .connected
        }
    }
    
    public func observeHealth(_ cb: @escaping (HealthChecker) -> ()) -> NotificationSubscription {
        return NotificationCenter.default.subscribe(toNotificationNamed: .HealthCheckerStatusDidChange) { _ in cb(self) }
    }
    
    internal func dispatch() {
        NotificationCenter.default.post(name: .HealthCheckerStatusDidChange, object: nil)
    }
    
    public func shutdown() {
        subscription.unsubscribe()
    }
}

public protocol NotificationSubscription {
    func unsubscribe() -> Void
}

public class SingleNotificationSubscription: NotificationSubscription {
    private let observer: NSObjectProtocol
    public let center: NotificationCenter
    
    private var unsubscribed = false
    
    public init(center: NotificationCenter, name: NSNotification.Name?, object: Any?, queue: OperationQueue?, handler: @escaping (Notification) -> ()) {
        self.center = center
        observer = center.addObserver(forName: name, object: object, queue: queue, using: handler)
    }
    
    deinit {
        if !unsubscribed {
            unsubscribe()
        }
    }
    
    public func unsubscribe() {
        unsubscribed = true
        center.removeObserver(observer)
    }
}

public class ManyNotificationSubscription: NotificationSubscription {
    private let subscriptions: [NotificationSubscription]
    public let center: NotificationCenter
    
    public typealias PackedNotification = (name: NSNotification.Name?, object: Any?, queue: OperationQueue?)
    
    public init(center: NotificationCenter, notifications: [PackedNotification], handler: @escaping (Notification) -> ()) {
        self.subscriptions = notifications.map { name, object, queue in
            center.subscribe(toNotificationNamed: name, object: object, queue: queue, using: handler)
        }
        self.center = center
    }
    
    deinit {
        unsubscribe()
    }
    
    public func unsubscribe() {
        subscriptions.forEach {
            $0.unsubscribe()
        }
    }
}

private extension NotificationCenter {
    func subscribe(toNotificationNamed name: NSNotification.Name? = nil, object: Any? = nil, queue: OperationQueue? = nil, using block: @escaping (Notification) -> ()) -> NotificationSubscription {
        SingleNotificationSubscription(center: self, name: name, object: object, queue: queue, handler: block)
    }
    
    func subscribe(toNotificationsNamed names: [NSNotification.Name], using block: @escaping (Notification) -> ()) -> NotificationSubscription {
        ManyNotificationSubscription(center: self, notifications: names.map { (name: $0, object: nil, queue: nil) }, handler: block)
    }
    
    func subscribe(toNotificationsNamed names: [String], using block: @escaping (Notification) -> ()) -> NotificationSubscription {
        ManyNotificationSubscription(center: self, notifications: names.map { (name: .init($0), object: nil, queue: nil) }, handler: block)
    }
    
    func subscribe(toNotifications notifications: [ManyNotificationSubscription.PackedNotification], using block: @escaping (Notification) -> ()) -> NotificationSubscription {
        ManyNotificationSubscription(center: self, notifications: notifications, handler: block)
    }
}
