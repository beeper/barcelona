//
//  BridgeStatusCommand.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 8/6/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import Barcelona
import BarcelonaEvents

public enum BridgeState: String, Codable {
    case starting = "STARTING"
    case unconfigured = "UNCONFIGURED"
    case connecting = "CONNECTING"
    case backfilling = "BACKFILLING"
    case connected = "CONNECTED"
    case transientDisconnect = "TRANSIENT_DISCONNECT"
    case badCredentials = "BAD_CREDENTIALS"
    case unknownError = "UNKNOWN_ERROR"
    case loggedOut = "LOGGED_OUT"
}

public struct BridgeStatusCommand: Codable {
    public var state_event: BridgeState
    public var ttl: TimeInterval
    public var error: String?
    public var message: String?
    public var remote_id: String?
    public var remote_name: String?
}

private extension HealthChecker.AuthenticationState {
    var abnormalState: BridgeState? {
        switch self {
        case .authenticated:
            return nil
        case .none:
            return .unconfigured
        case .registrationFailure:
            return .badCredentials
        case .validationFaliure:
            return .unknownError
        case .signedOut:
            return .loggedOut
        }
    }
}

private extension HealthChecker.ConnectionState {
    var abnormalState: BridgeState? {
        switch self {
        case .connected:
            return nil
        case .errored:
            return .unknownError
        case .offline:
            return .transientDisconnect
        case .transientDisconnect:
            return .transientDisconnect
        }
    }
}

private extension BridgeState {
    private enum HealthClassification {
        case critical
        case normal
        
        var interval: TimeInterval {
            switch self {
            case .critical:
                return TimeInterval(BLRuntimeConfiguration.criticalHealthTTL)
            case .normal:
                return TimeInterval(BLRuntimeConfiguration.healthTTL)
            }
        }
    }
    
    private var classification: HealthClassification {
        switch self {
        case .transientDisconnect:
            return .critical
        case .unknownError:
            return .critical
        default:
            return .normal
        }
    }
    
    var ttl: TimeInterval {
        classification.interval
    }
}

public extension BridgeStatusCommand {
    static var current: BridgeStatusCommand {
        let authenticationState = HealthChecker.shared.authenticationState
        let connectionState = HealthChecker.shared.connectionState
        let state_event = authenticationState.abnormalState ?? connectionState.abnormalState ?? .connected
        
        return BridgeStatusCommand(
            state_event: state_event,
            ttl: state_event.ttl,
            error: authenticationState.error ?? connectionState.error,
            message: authenticationState.message ?? connectionState.message,
            remote_id: nil,
            remote_name: nil
        )
    }
}
