////  Accounts.swift
//  grapple
//
//  Created by Eric Rabil on 9/27/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import SwiftCLI
import Barcelona

class AccountManagement: CommandGroup {
    let name = "accounts"
    let shortDescription = "interact with IMAccounts"
    
    class ListCommand: EphemeralBarcelonaCommand {
        let name = "list"
        
        func execute() throws {
            print(IMAccountController.shared.accounts.renderTextTable())
        }
    }
    
    class GetCommand: EphemeralBarcelonaCommand {
        let name = "get"
        
        @Param
        var id: String
        
        func execute() throws {
            guard let account = IMAccountController.shared.account(forUniqueID: id) else {
                print(404)
                return
            }
            
            print([account].renderTextTable())
        }
    }
    
    class EnrollCommand: BarcelonaCommand {
        let name = "enroll"
        
        @Param
        var id: String
        
        func execute() throws {
            guard let account = IMAccountController.shared.account(forUniqueID: id) else {
                print(404)
                return
            }
            
            account.enrollSelfDeviceInSMSRelay()
            
            
        }
    }
    
    let children: [Routable] = [ListCommand(), GetCommand(), EnrollCommand()]
}
