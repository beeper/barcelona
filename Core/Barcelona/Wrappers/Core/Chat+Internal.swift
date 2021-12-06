//
//  Chat+Internal.swift
//  Barcelona
//
//  Created by Eric Rabil on 11/2/21.
//

import Foundation
import IMCore

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
            guard handlesAreiMessageEligible([id]) else {
                fallthrough
            }
            
            return iMessageHandle(forID: id)!
        default:
            return smsAccount.imHandle(withID: id)
        }
    }
}
