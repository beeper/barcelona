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
        subscription = NotificationCenter.default.subscribe(toNotificationsNamed: ConnectionState.notifications) { _,_ in
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
        let account = IMAccountController.shared.iMessageAccount
        
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
            if !IMAccountController.shared.iMessageAccount.isConnected {
                return .offline
            }
            
            return .connected
        }
    }
    
    public func observeHealth(_ cb: @escaping (HealthChecker) -> ()) -> NotificationSubscription {
        return NotificationCenter.default.subscribe(toNotificationNamed: .HealthCheckerStatusDidChange) { _,_ in cb(self) }
    }
    
    internal func dispatch() {
        NotificationCenter.default.post(name: .HealthCheckerStatusDidChange, object: nil)
    }
    
    public func shutdown() {
        subscription.unsubscribe()
    }
}
