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

import BarcelonaMautrixIPCProtobuf

public typealias BridgeStatusCommand = PBBridgeStatus

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
        
        let registrationFailureReason = account.registrationFailureReason
        
        if registrationFailureReason == .irreparableFailure, CBFeatureFlags.beeper {
            return "An error occurred while activating iMessage. Please contact Beeper support to resolve this issue."
        }
        
        if let alertInfo = account.registrationFailureAlertInfo, var body = alertInfo["body"] as? String {
            if let action = alertInfo["action"] as? [AnyHashable: Any], let url = action["url"] as? String {
                body += " " + url
            }
            
            return body
        }
        
        switch registrationFailureReason {
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
            return .with {
                $0.stateEvent = "UNCONFIGURED"
                $0.ttl = 360
            }
        default:
            break
        }
        
        lazy var fullName: String? = account?.loginIMHandle?.fullName
        
        lazy var allAddresses: [String] = {
            if let aliases = account?.aliases {
                return aliases
            } else if let remoteID = remoteID {
                return [remoteID]
            } else {
                return []
            }
        }()
        
        lazy var addresses: [String] = {
            if let aliases = account?.vettedAliases {
                return aliases
            } else if let remoteID = remoteID {
                return [remoteID]
            } else {
                return []
            }
        }()
        
        return .with { command in
            command.stateEvent = state.rawValue
            command.ttl = state == .connected ? 3600 : 240
            if let error = IMAccountController.shared.error {
                command.error = error
            }
            if let message = IMAccountController.shared.message {
                command.message = message
            }
            if let remoteID = remoteID {
                command.remoteID = remoteID
            }
            if let fullName = fullName {
                command.remoteName = fullName
            }
            command.info = .with { info in
                info.mapping["sms_forwarding_enabled"] = .bool(IMAccountController.shared.accounts(for: .sms())?.first?.allowsSMSRelay == true)
                info.mapping["sms_forwarding_capable"] = .bool(IMAccountController.shared.accounts(for: .sms())?.first?.isSMSRelayCapable == true)
                info.mapping["active_alias_count"] = .int(addresses.count)
                info.mapping = [
                    "sms_forwarding_enabled": .bool(IMAccountController.shared.accounts(for: .sms())?.first?.allowsSMSRelay == true),
                    "sms_forwarding_capable": .bool(IMAccountController.shared.accounts(for: .sms())?.first?.isSMSRelayCapable == true),
                    "active_alias_acount": .int(addresses.count),
                    "active_phone_number_count": .int(addresses.filter(\.isPhoneNumber).count),
                    "active_email_count": .int(addresses.filter(\.isEmail).count),
                    "alias_count": .int(allAddresses.count),
                    "phone_number_count": .int(allAddresses.filter(\.isPhoneNumber).count),
                    "email_count": .int(allAddresses.filter(\.isEmail).count),
                    "loginStatusMessage": account?.loginStatusMessage.map(PBMetadataValue.string(_:))
                ].compactMapValues { $0 }
            }
        }
    }
}

extension PBMetadataValue: ExpressibleByBooleanLiteral {
    public static func bool(_ value: Bool) -> PBMetadataValue {
        .init(booleanLiteral: value)
    }

    public init(booleanLiteral value: Bool) {
        self = .with {
            $0.value = .bool(value)
        }
    }
}

extension PBMetadataValue: ExpressibleByStringLiteral {
    public static func string(_ value: String) -> PBMetadataValue {
        .init(stringLiteral: value)
    }

    public init(stringLiteral value: String) {
        self = .with {
            $0.value = .string(value)
        }
    }
}

extension PBMetadataValue: ExpressibleByIntegerLiteral {
    public static func int(_ value: Int) -> PBMetadataValue {
        .init(integerLiteral: value)
    }

    public init(integerLiteral value: Int) {
        self = .with {
            $0.value = .int64(Int64(value))
        }
    }
}

extension PBMapping {
    init(_ metadata: [String: MetadataValue]) {
        self = .with { mapping in
            
        }
    }
}

extension MetadataValue {
    var pb: PBMetadataValue {
        switch self {
            case .array(let values):
            return .with {
                $0.value = .array(.with {
                    $0.values = values.map(\.pb)
                })
            }
            case .dictionary(let dictionary):
            return .with {
                $0.value = .mapping(.with {
                    $0.mapping = dictionary.mapValues {
                        $0.pb
                    }
                })
            }
            case .int(let int):
            return .with {
                $0.value = .int64(Int64(int))
            }
            case .double(let double):
            return .with {
                $0.value = .double(double)
            }
            case .boolean(let bool):
            return .with {
                $0.value = .bool(bool)
            }
            case .string(let string):
            return .with {
                $0.value = .string(string)
            }
            case .nil:
            return .with {
                $0.value = nil
            }
        }
    }
}

extension Dictionary where Key == String, Value == MetadataValue {
    var pb: PBMapping {
        MetadataValue.dictionary(self).pb.mapping
    }
}