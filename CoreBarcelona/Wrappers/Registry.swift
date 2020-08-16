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
    
    func chat(withGroupID groupID: String) -> Chat? {
        guard let imChat = imChat(withGroupID: groupID) else {
            return nil
        }
        
        return Chat(imChat)
    }
    
    /// I hate IMCore. Seriously, delete the framework and start over.
    func imChat(withGroupID groupID: String) -> IMChat? {
        return IMChatRegistry.shared.allExistingChats.first {
            $0.groupID == groupID
        }
    }
    
    func account(withUniqueID uniqueID: String) -> IMAccount {
        return IMAccountController.sharedInstance()!.account(forUniqueID: uniqueID)
    }
    
    func imHandle(withID id: String) -> IMHandle? {
        guard let account = IMAccountController.sharedInstance().activeIMessageAccount ?? IMAccountController.sharedInstance().activeSMSAccount, let handle = account.imHandle(withID: id) else { return nil }
        
        return handle
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
    
    private func resolve(service: String) -> IMService? {
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
