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
    
    func account(withUniqueID uniqueID: String) -> IMAccount {
        return IMAccountController.sharedInstance()!.account(forUniqueID: uniqueID)
    }
    
    func imHandle(withID id: String) -> IMHandle? {
        if let iMessageAccount = IMAccountController.sharedInstance()?.activeIMessageAccount, let handle = imHandle(withID: id, onAccount: iMessageAccount) {
            return handle
        } else if let SMSAccount = IMAccountController.sharedInstance()?.activeSMSAccount, let handle = imHandle(withID: id, onAccount: SMSAccount) {
            return handle
        } else {
            return nil
        }
    }
    
    func imHandle(withID id: String, onService service: String) -> IMHandle? {
        guard let account = bestAccount(for: service) else {
            return nil
        }
        
        return imHandle(withID: id, onAccount: account)
    }
    
    func imHandle(withID id: String, onService service: IMService) -> IMHandle? {
        guard let account = bestAccount(for: service) else {
            return nil
        }
        
        return imHandle(withID: id, onAccount: account)
    }
    
    func imHandle(withID id: String, onAccount account: IMAccount) -> IMHandle? {
        account.imHandle(withID: id) ?? account.existingIMHandle(withID: id)
    }
    
    func suitableHandle(for service: String) -> IMHandle? {
        guard let impl = self.resolve(service: service) else {
            return nil
        }
        
        return suitableHandle(for: impl)
    }
    
    func suitableHandle(for service: IMService) -> IMHandle? {
        guard let account = bestAccount(for: service) else {
            return nil
        }
        
        return account.loginIMHandle
    }
    
    func bestAccount(for service: String) -> IMAccount? {
        guard let service = resolve(service: service) else {
            return nil
        }
        
        return bestAccount(for: service)
    }
    
    func bestAccount(for service: IMService) -> IMAccount? {
        IMAccountController.sharedInstance()?.bestAccount(forService: service)
    }
    
    func resolve(service: String) -> IMService? {
        let IMServiceAgentImpl = NSClassFromString("IMServiceAgentImpl") as! IMServiceAgent.Type
        
        return IMServiceAgentImpl.shared()?.service(withName: service)
    }
    
    func iMessageAccount() -> IMAccount? {
        return IMAccountController.sharedInstance().activeIMessageAccount
    }
    
    func SMSAccount() -> IMAccount? {
        return IMAccountController.sharedInstance().activeSMSAccount
    }
}
