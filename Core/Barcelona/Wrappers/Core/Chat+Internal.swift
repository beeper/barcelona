//
//  Chat+Internal.swift
//  Barcelona
//
//  Created by Eric Rabil on 11/2/21.
//

import Foundation
import IMCore
import Logging
import Pwomise

private let log = Logger(label: "ChatLocator")

/// APIs for creating a chat!
public struct ChatLocator {
    static func handleIsRegisteredForIMessage(_ handle: String) async throws -> String? {
        do {
            let (id, status) = try await IDSResolver.resolveStatus(for: handle, on: .iMessage)
            if status == .available {
                return id
            }
            return nil
        } catch {
            log.error("Failed to resolve IDS status for \(handle): \(error)")
        }
        return nil
    }

    public enum ServiceResult {
        case service(IMServiceStyle, String)
        case failed(String)
    }

    public static func service(for handle: String) async throws -> ServiceResult {
        if handle.isBusinessID {
            return .service(.iMessage, handle)
        }

        let registered = try await handleIsRegisteredForIMessage(handle)

        if let registered {
            return .service(.iMessage, registered)
        }
        guard handle.isPhoneNumber else {
            return .failed("This address is not registered with iMessage, nor can you SMS it.")
        }
        guard IMServiceImpl.smsEnabled() else {
            return .failed("You are not currently capable of using SMS.")
        }
        if handle.starts(with: "+") {
            log.info("Returning fake SMS result for a well formed phone number")
            return .service(.SMS, handle)
        } else if handle.count == 10 {
            // Whoever is asking didn't ask us for a proper phone number with a country code
            // They're probably North American, so just prefix the result with +1
            let cleanedUpHandle = "+1\(handle)"
            log.info("Returning fake SMS result, before \(handle) after \(cleanedUpHandle)")
            return .service(.SMS, cleanedUpHandle)
        } else {
            log.info("Returning a failed result because even though this looks like a phone number for SMS we don't trust it: \(handle)")
            return .failed("SMS forwarding is enabled but request does not look like a phone number")
        }
    }

    public enum SenderGUIDResult {
        case guid(String)
        case failed(String)
    }

    public static func senderGUID(for handle: String) async throws -> SenderGUIDResult {
        let result = try await service(for: handle)
        switch result {
        case .service(let service, let matchingHandle):
            return .guid(service.rawValue + ";-;" + matchingHandle)
        case .failed(let message):
            return .failed(message)
        }
    }
}

// MARK: - Utilities
extension IMChat {
    static func iMessageHandle(forID id: String) -> IMHandle? {
        IMAccountController.shared.iMessageAccount?.imHandle(withID: id)
    }

    static var smsAccount: IMAccount {
        IMAccountController.shared.activeSMSAccount ?? IMAccount(service: IMServiceStyle.SMS.service)!
    }

    static func bestHandle(forID id: String, service: IMServiceStyle) -> IMHandle {
        switch service {
        case .iMessage:
            return iMessageHandle(forID: id)!
        default:
            return smsAccount.imHandle(withID: id)
        }
    }
}
