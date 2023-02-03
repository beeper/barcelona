//
//  Chat+Internal.swift
//  Barcelona
//
//  Created by Eric Rabil on 11/2/21.
//

import Foundation
import IMCore
import Pwomise

/// APIs for creating a chat!
public struct ChatLocator {
    static func handleIsRegisteredForIMessage(_ handle: String) async throws -> Bool {
        await withCheckedContinuation { continuation in
            do {
                try BLResolveIDStatusForIDs([handle], onService: .iMessage) { result in
                    continuation.resume(returning: result[handle] == .available)
                }
            } catch {
                continuation.resume(returning: false)
            }
        }
    }

    public enum ServiceResult {
        case service(IMServiceStyle)
        case failed(String)
    }

    public static func service(for handle: String) async throws -> ServiceResult {
        if handle.isBusinessID {
            return .service(.iMessage)
        }

        let registered = try await handleIsRegisteredForIMessage(handle)

        if registered {
            return .service(.iMessage)
        }
        guard handle.isPhoneNumber else {
            return .failed("This address is not registered with iMessage, nor can you SMS it.")
        }
        guard IMServiceImpl.smsEnabled() else {
            return .failed("You are not currently capable of using SMS.")
        }
        return .service(.SMS)
    }

    public enum SenderGUIDResult {
        case guid(String)
        case failed(String)
    }
    
    public static func senderGUID(for handle: String) async throws -> SenderGUIDResult {
        let result = try await service(for: handle)
            switch result {
            case .service(let service):
                return .guid(service.rawValue + ";-;" + handle)
            case .failed(let message):
                return .failed(message)
            }
    }
    
    public enum ChatResult {
        case existing(Chat)
        case created(Chat)
        case failed(String)
    }
}

// MARK: - Utilities
internal extension Chat {
    static func handlesAreiMessageEligible(_ handles: [String]) -> Bool {
        guard let statuses = try? BLResolveIDStatusForIDs(handles, onService: .iMessage) else {
            return false
        }
        
        return statuses.values.allSatisfy {
            $0 == .available
        }
    }
    
    static func iMessageHandle(forID id: String) -> IMHandle? {
        IMAccountController.shared.iMessageAccount?.imHandle(withID: id)
    }
    
    static var smsAccount: IMAccount {
        IMAccountController.shared.activeSMSAccount ?? IMAccount(service: IMServiceStyle.SMS.service!)!
    }
    
    static func homogenousHandles(forIDs ids: [String]) -> [IMHandle] {
        if handlesAreiMessageEligible(ids) {
            return ids.compactMap(iMessageHandle(forID:))
        }
        
        return ids.map(smsAccount.imHandle(withID:))
    }
    
    static func bestHandle(forID id: String) -> IMHandle {
        homogenousHandles(forIDs: [id]).first!
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
