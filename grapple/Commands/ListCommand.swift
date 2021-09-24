//
//  ListCommand.swift
//  grapple
//
//  Created by Eric Rabil on 8/9/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import SwiftCLI
import IMCore

class ListCommand: CommandGroup {
    var shortDescription = "list different entities in IMCore"
    
    let name: String = "list"
    
    let children: [Routable] = [ListAccountsCommand()]
    
    class ListAccountsCommand: EphemeralBarcelonaCommand {
        let name = "accounts"
        
        func execute() throws {
            let accounts = IMAccountController.__sharedInstance().accounts
            
            print(IMAccountController.__sharedInstance().accounts.renderTextTable(), accounts)
        }
    }
}
