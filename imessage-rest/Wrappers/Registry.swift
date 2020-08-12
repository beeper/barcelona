//
//  ChatRegistry.swift
//  imcore-rest
//
//  Created by Eric Rabil on 7/23/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

class Registry {
    static let sharedInstance = Registry()
    
    func chat(withGUID guid: String) -> IMChat? {
        return IMChatRegistry.shared._chatInstance(forGUID: guid)
    }
    
    func account(withUniqueID uniqueID: String) -> IMAccount {
        return IMAccountController.sharedInstance()!.account(forUniqueID: uniqueID)
    }
    
    func imHandle(withID id: String) -> IMHandle? {
        guard let account = IMAccountController.sharedInstance().activeIMessageAccount ?? IMAccountController.sharedInstance().activeSMSAccount, let handle = account.imHandle(withID: id) else { return nil }
        
        return handle
    }
    
    func iMessageAccount() -> IMAccount? {
        return IMAccountController.sharedInstance().activeIMessageAccount
    }
    
    func SMSAccount() -> IMAccount? {
        return IMAccountController.sharedInstance().activeSMSAccount
    }
}
