//
//  ChatRegistry.swift
//  imcore-rest
//
//  Created by Eric Rabil on 7/23/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

public extension IMMe {
    static var sharedInstance: IMMe {
        perform(Selector("me"))!.takeUnretainedValue() as! IMMe
    }
}

private extension Array where Element: Hashable {
    var unique: [Element] {
        Array(Set(self))
    }
}

public class Registry {
    public static let sharedInstance = Registry()
    
    public func account(withUniqueID uniqueID: String) -> IMAccount {
        return IMAccountController.sharedInstance().account(forUniqueID: uniqueID)
    }
    
    public func imHandle(withID id: String) -> IMHandle? {
        if let iMessageAccount = IMAccountController.sharedInstance().activeIMessageAccount, let handle = imHandle(withID: id, onAccount: iMessageAccount) {
            return handle
        } else if let SMSAccount = IMAccountController.sharedInstance().activeSMSAccount, let handle = imHandle(withID: id, onAccount: SMSAccount) {
            return handle
        } else {
            return nil
        }
    }
    
    public func imHandles(forPerson person: IMPerson) -> [IMHandle] {
        allAccounts.flatMap {
            $0.imHandles(for: person)
        }
    }
    
    public func imHandleIDs(forPerson person: IMPerson) -> [String] {
        imHandles(forPerson: person).map {
            $0.id
        }.unique
    }

    public var allMeHandles: [IMHandle] {
        allAccounts.flatMap { account in
            account.aliases.compactMap { handle in
                account.imHandle(withID: handle)
            }
        }
    }
    
    public var uniqueMeHandleIDs: [String] {
        allAccounts.flatMap { account in
            account.aliases
        }.unique
    }

    public var allAccounts: [IMAccount] {
        IMAccountController.sharedInstance().accounts
    }
    
    public func imHandle(withID id: String, onService service: String) -> IMHandle? {
        guard let account = bestAccount(for: service) else {
            return nil
        }
        
        return imHandle(withID: id, onAccount: account)
    }
    
    public func imHandle(withID id: String, onService service: IMService) -> IMHandle? {
        guard let account = bestAccount(for: service) else {
            return nil
        }
        
        return imHandle(withID: id, onAccount: account)
    }
    
    public func imHandle(withID id: String, onAccount account: IMAccount) -> IMHandle? {
        account.imHandle(withID: id) ?? account.existingIMHandle(withID: id)
    }
    
    public func suitableHandle(for service: String) -> IMHandle? {
        guard let impl = self.resolve(service: service) else {
            return nil
        }
        
        return suitableHandle(for: impl)
    }
    
    public func suitableHandle(for service: IMService) -> IMHandle? {
        guard let account = bestAccount(for: service) else {
            return nil
        }
        
        return account.loginIMHandle
    }
    
    public func bestAccount(for service: String) -> IMAccount? {
        guard let service = resolve(service: service) else {
            return nil
        }
        
        return bestAccount(for: service)
    }
    
    public func bestAccount(for service: IMService) -> IMAccount? {
        IMAccountController.sharedInstance().bestAccount(forService: service)
    }
    
    public func resolve(service: String) -> IMService? {
        let IMServiceAgentImpl = NSClassFromString("IMServiceAgentImpl") as! IMServiceAgent.Type
        
        return IMServiceAgentImpl.shared()?.service(withName: service)
    }
    
    public func iMessageAccount() -> IMAccount? {
        return IMAccountController.sharedInstance().activeIMessageAccount
    }
    
    public func SMSAccount() -> IMAccount? {
        return IMAccountController.sharedInstance().activeSMSAccount
    }
    
    public var smsServiceEnabled: Bool {
        ((IMService.sms() as? IMServiceImpl)?.isEnabled()) ?? false
    }
    
    public var callServiceEnabled: Bool {
        ((IMService.call() as? IMServiceImpl)?.isEnabled()) ?? false
    }
}
