//
//  ChatRegistry.swift
//  imcore-rest
//
//  Created by Eric Rabil on 7/23/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

private extension Array where Element: Hashable {
    var unique: [Element] {
        Array(Set(self))
    }
}

public class Registry {
    public static let sharedInstance = Registry()
    
    public func account(withUniqueID uniqueID: String) -> IMAccount {
        return IMAccountController.shared.account(forUniqueID: uniqueID)
    }
    
    public func imHandle(withID id: String) -> IMHandle? {
        if let account = IMAccountController.shared.iMessageAccount, let handle = imHandle(withID: id, onAccount: account) {
            return handle
        } else if let SMSAccount = IMAccountController.shared.activeSMSAccount, let handle = imHandle(withID: id, onAccount: SMSAccount) {
            return handle
        } else {
            return nil
        }
    }
    
    public func imHandles(forContact contact: CNContact) -> [IMHandle] {
        Array(IMHandleRegistrar.sharedInstance().handles(forCNIdentifier: contact.id))
    }
    
    public func imHandleIDs(forContact contact: CNContact) -> [String] {
        imHandles(forContact: contact).map(\.id).unique
    }

    public var allMeHandles: [IMHandle] {
        allAccounts.flatMap { account in
            account.aliases.compactMap(account.imHandle(withID:))
        }
    }
    
    public var uniqueMeHandleIDs: [String] {
        allAccounts.flatMap(\.aliases).unique
    }

    public var allAccounts: [IMAccount] {
        IMAccountController.shared.accounts
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
        if let serviceImpl = service as? IMServiceImpl, let account = serviceImpl.value(forKey: "bestAccount") as? IMAccount {
            return account
        }
        
        return IMAccountController.shared.bestAccount(forService: service)
    }
    
    public func resolve(service: String) -> IMService? {
        let IMServiceAgentImpl = NSClassFromString("IMServiceAgentImpl") as! IMServiceAgent.Type
        
        return IMServiceAgentImpl.shared()?.service(withName: service)
    }
    
    public func iMessageAccount() -> IMAccount? {
        return IMAccountController.shared.iMessageAccount
    }
    
    public func SMSAccount() -> IMAccount? {
        return IMAccountController.shared.activeSMSAccount
    }
    
    private func _connect() {
        if _fastPath(IMDaemonController.shared().isConnected) {
            return
        }
        
        IMDaemonController.shared().connectToDaemon(withLaunch: true, capabilities: FZListenerCapabilities.defaults_, blockUntilConnected: true)
    }
    
    public var smsServiceEnabled: Bool {
        _connect()
        return ((IMService.sms() as? IMServiceImpl)?.isEnabled()) ?? false
    }
    
    public var callServiceEnabled: Bool {
        _connect()
        return ((IMService.call() as? IMServiceImpl)?.isEnabled()) ?? false
    }
}
