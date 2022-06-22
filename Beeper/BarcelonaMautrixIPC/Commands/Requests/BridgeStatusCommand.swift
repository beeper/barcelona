//
//  BridgeStatusCommand.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 8/6/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import Barcelona
import IMCore
import IMFoundation
import AnyCodable

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

public struct BridgeStatusCommand: Codable, Equatable {
    public var state_event: BridgeState
    public var ttl: TimeInterval
    public var error: String?
    public var message: String?
    public var remote_id: String?
    public var remote_name: String?
    public var info: [String: AnyCodable]
}

private extension IMAccount {
    var isPlaceholder: Bool {
        uniqueID == "PlaceholderAccount"
    }
}

private extension IMAccount {
    var registrationSuccessDate: Date? {
        dictionary["RegistrationSuccessDate"] as? Date
    }
    
    var registrationFailureDate: Date? {
        dictionary["RegistrationFailureDate"] as? Date
    }
}

extension RawRepresentable where RawValue: Comparable {
    public static func >= (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue >= rhs.rawValue
    }
    
    public static func <= (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue <= rhs.rawValue
    }
    
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    public static func > (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue > rhs.rawValue
    }
}

private extension IMAccountController {
    var state: BridgeState {
        // If there is no iMessage account, we are certainly unconfigured.
        guard let account = iMessageAccount else {
            return .unconfigured
        }
        
        // If the account is a placeholder, we are certainly unconfigured.
        guard !account.isPlaceholder else {
            return .unconfigured
        }
        
        // If the account has any of the following registration failure reasons, it is most certainly not working.
        if [IMAccountRegistrationFailureReason.irreparableFailure, .expiredDeviceCredentials, .loginFailed, .badCredentials, .badDeviceCredentials, .badPushToken, .cancelled].contains(account.registrationFailureReason) {
            return .badCredentials
        }
        
        // The value of the last registration failure, if the registration success date does not exist or is before the failure date.
        lazy var registrationFailureDate: Date? = account.registrationFailureDate.flatMap { registrationFailureDate in
            if let registrationSuccessDate = account.registrationSuccessDate {
                if registrationFailureDate > registrationSuccessDate {
                    return registrationFailureDate
                }
            } else if account.registrationStatus <= .failed {
                return registrationFailureDate
            }
            return nil
        }
        
        // If there is no authorization token, we are certainly not authorized.
        var isAuthorized: Bool {
            account.authorizationToken != nil
        }
        
        // If the account has a loggedIn status, or if justLoggedIn is true, or if the account says it is connected, then we will assume that we are logged in.
        var isLoggedIn: Bool {
            account.loginStatus == .statusLoggedIn || account.justLoggedIn || account.isConnected
        }
        
        var isRegistered: Bool {
            account.isRegistered
        }
        
        // True if the account has conditions that should allow it to properly register
        var isProbablyAboutToRegister: Bool {
            // If the account is inactive, it cannot register.
            if !account.isActive {
                return false
            }
            // If the account is authorized, we are probably about to register.
            if isAuthorized {
                return true
            }
            // If the account is logged in, we are probably about to register.
            if isLoggedIn {
                return true
            }
            // If the account just logged in, we are probably about to register.
            if account.justLoggedIn {
                return true
            }
            // If the account is connecting, we are probably about to register.
            if account.isConnecting {
                return true
            }
            // Otherwise, we are not about to register.
            return false
        }
        
        // True if the account failed to register, has a known registraiton failure reason, or most recently failed to register
        var hasAccountError: Bool {
            account.registrationStatus == .failed || account.registrationFailureReason > .unknownError || registrationFailureDate != nil
        }
        
        // If we are registered but disconnected, consider that a TRANSIENT_DISCONNECT
        if isRegistered && account.loginStatus == .statusDisconnected {
            return .transientDisconnect
        }
        
        // If we are registered, logged in, and have no account error, we are connected.
        if isRegistered && isLoggedIn && !hasAccountError {
            return .connected
        // Otherwise, if we are probably about to register, then we are connecting.
        } else if isProbablyAboutToRegister {
            return .connecting
        // Otherwise, if there is any kind of account error, we are in bad credentials.
        } else if hasAccountError {
            return .badCredentials
        // Otherwise, we don't know what state we're in, but it isn't good.
        } else {
            return .unknownError
        }
    }
    
    /// Translates IMCore enum to string error messages
    var error: String? {
        guard let account = iMessageAccount else {
            return nil
        }
        
        if let alertInfo = account.registrationFailureAlertInfo, var body = alertInfo["body"] as? String {
            if let action = alertInfo["action"] as? [AnyHashable: Any], let url = action["url"] as? String {
                body += " " + url
            }
            
            return body
        }
        
        switch account.registrationFailureReason {
        case .noError:
            return nil
        case .unknownError:
            return nil
        case .invalidLogin:
            return "invalid_login"
        case .invalidPassword:
            return "invalid_password"
        case .loginFailed:
            return "login_failed"
        case .cannotConnect:
            return "cannot_connect"
        case .badDeviceID:
            return "bad_device_id"
        case .badPushToken:
            return "bad_push_token"
        case .serverDenied:
            return "server_denied"
        case .tooManyAttempts:
            return "too_many_attempts"
        case .accountUpdateNeeded:
            return "account_update_needed"
        case .accountNotAuthorized:
            return "account_not_authorized"
        case .newPasswordNeeded:
            return "new_password_needed"
        case .permanentlyBlocked:
            return "permanently_blocked"
        case .temporarilyBlocked:
            return "temporarily_blocked"
        case .cancelled:
            return "cancelled"
        case .notSupported:
            return "not_supported"
        case .badDeviceCredentials:
            return "bad_device_credentials"
        case .expiredDeviceCredentials:
            return "expired_device_credentials"
        case .serverError:
            return "server_error"
        case .unconfirmedAlias:
            return "unconfirmed_alias"
        case .registrationUnsupported:
            return "registration_unsupported"
        case .registrationNoAliasesSpecified:
            return "registration_no_aliases_specified"
        case .unsupportedManagedID:
            return "unsupported_managed_id"
        case .disabledSMSAuthentication:
            return "disabled_sms_authentication"
        case .deniedByServer:
            return "denied_by_server"
        case .badCredentials:
            return "bad_credentials"
        case .irreparableFailure:
            return "irreparable_failure"
        @unknown default:
            return "unknown_error"
        }
    }
    
    var message: String? {
        iMessageAccount?.registrationFailureAlertInfo?[IMAccountRegistrationFailedAlertMessageKey] as? String
    }
}

public extension BridgeStatusCommand {
    static var current: BridgeStatusCommand {
        let account = IMAccountController.shared.iMessageAccount
        let state = IMAccountController.shared.state
        let remoteID = account?.strippedLogin ?? nil
        
        switch remoteID {
        case .none, "unknown", "":
            return BridgeStatusCommand(state_event: .unconfigured, ttl: 240, error: nil, message: nil, remote_id: nil, remote_name: nil, info: [:])
        default:
            break
        }
        
        var addresses: [String] {
            if let aliases = account?.vettedAliases {
                return aliases
            } else if let remoteID = remoteID {
                return [remoteID]
            } else {
                return []
            }
        }
        
        return BridgeStatusCommand(
            state_event: state,
            ttl: state == .connected ? 3600 : 240,
            error: IMAccountController.shared.error,
            message: IMAccountController.shared.message,
            remote_id: remoteID, // Apple ID – absent when unconfigured. logged out includes the remote id, and then goes to unconfigured. everything else must include the remote ID
            remote_name: IMMe.me().fullName, // Account Name
            info: [
                "addresses": AnyCodable(addresses),
                "primary_address": AnyCodable(account?.displayName)
            ]
        )
    }
}
