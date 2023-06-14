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
        return .service(.SMS, handle)
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
