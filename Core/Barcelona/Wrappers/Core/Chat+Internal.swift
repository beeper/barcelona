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
    static func handleIsRegisteredForIMessage(_ handle: String) -> Promise<Bool> {
        Promise { resolve in
            do {
                try BLResolveIDStatusForIDs([handle], onService: .iMessage) { result in
                    resolve(result[handle] == .available)
                }
            } catch {
                resolve(false)
            }
        }
    }
    
    public enum ServiceResult {
        case service(IMServiceStyle)
        case failed(String)
    }
    
    public static func service(for handle: String) -> Promise<ServiceResult> {
        if handle.isBusinessID {
            return .success(.service(.iMessage))
        }
        
        return handleIsRegisteredForIMessage(handle).then { registered in
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
    }
    
    public enum SenderGUIDResult {
        case guid(String)
        case failed(String)
    }
    
    public static func senderGUID(for handle: String) -> Promise<SenderGUIDResult> {
        service(for: handle).then { result in
            switch result {
            case .service(let service):
                return .guid(service.rawValue + ";-;" + handle)
            case .failed(let message):
                return .failed(message)
            }
        }
    }
    
    public enum ChatResult {
        case existing(Chat)
        case created(Chat)
        case failed(String)
    }
    
    public static func chat(for handle: String) -> Promise<ChatResult> {
        if let handles = IMHandleRegistrar.sharedInstance().allIMHandles(), !handles.isEmpty {
            let chats = handles.compactMap(IMChatRegistry.shared.existingChat(for:))
            if !chats.isEmpty {
                if chats.count == 1 {
                    return .success(.existing(Chat(chats.first!)))
                } else {
                    if let iMessageChat = chats.first(where: { $0.account.service == .iMessage() }) {
                        return .success(.existing(Chat(iMessageChat)))
                    } else {
                        return .success(.existing(Chat(chats.first!)))
                    }
                }
            } else {
                if let iMessageHandle = handles.first(where: { $0.service == .iMessage() }) {
                    return .success(.existing(Chat(IMChatRegistry.shared.chat(for: iMessageHandle))))
                }
            }
        }
        return service(for: handle).then { result in
            switch result {
            case .service(let style):
                return .created(Chat.directMessage(withHandleID: handle, service: style))
            case .failed(let message):
                return .failed(message)
            }
        }
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
