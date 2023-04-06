//
//  ChatRegistry.swift
//  imcore-rest
//
//  Created by Eric Rabil on 7/23/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

extension Array where Element: Hashable {
    fileprivate var unique: [Element] {
        Array(Set(self))
    }
}

class Registry {
    static let sharedInstance = Registry()

    func imHandle(withID id: String) -> IMHandle? {
        if let account = IMAccountController.shared.iMessageAccount,
            let handle = imHandle(withID: id, onAccount: account)
        {
            return handle
        } else if let SMSAccount = IMAccountController.shared.activeSMSAccount,
            let handle = imHandle(withID: id, onAccount: SMSAccount)
        {
            return handle
        } else {
            return nil
        }
    }

    var uniqueMeHandleIDs: [String] {
        allAccounts.flatMap(\.aliases).unique
    }

    var allAccounts: [IMAccount] {
        IMAccountController.shared.accounts
    }

    func imHandle(withID id: String, onAccount account: IMAccount) -> IMHandle? {
        account.imHandle(withID: id)
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

    func bestAccount(for service: IMService) -> IMAccount? {
        if let serviceImpl = service as? IMServiceImpl,
            let account = serviceImpl.value(forKey: "bestAccount") as? IMAccount
        {
            return account
        }

        return IMAccountController.shared.bestAccount(forService: service)
    }

    func resolve(service: String) -> IMService? {
        let IMServiceAgentImpl = NSClassFromString("IMServiceAgentImpl") as! IMServiceAgent.Type

        return IMServiceAgentImpl.shared()?.service(withName: service)
    }


    private func _connect() {
        if _fastPath(IMDaemonController.shared().isConnected) {
            return
        }

        IMDaemonController.shared()
            .connectToDaemon(
                withLaunch: true,
                capabilities: FZListenerCapabilities.defaults_,
                blockUntilConnected: true
            )
    }

    var smsServiceEnabled: Bool {
        _connect()
        return IMService.sms()?.isEnabled() ?? false
    }

    var callServiceEnabled: Bool {
        _connect()
        return IMService.call()?.isEnabled() ?? false
    }
}
