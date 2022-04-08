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
#if DEBUG
import BarcelonaMautrixIPC
#endif

class ListCommand: CommandGroup {
    var shortDescription = "list different entities in IMCore"
    
    let name: String = "list"
    
    var children: [Routable] = [ListAccountsCommand()]
    
    init() {
        #if DEBUG
        children = children + [ListContactsCommand()]
        #endif
    }
    
    class ListAccountsCommand: EphemeralBarcelonaCommand {
        let name = "accounts"
        
        func execute() throws {
            let accounts = IMAccountController.__sharedInstance().accounts
            
            print(IMAccountController.__sharedInstance().accounts.renderTextTable(), accounts)
        }
    }
    
    #if DEBUG
    class ListContactsCommand: EphemeralBarcelonaCommand {
        let name = "contacts"
        
        func execute() throws {
            let data = try JSONEncoder().encode(BMXGenerateContactList(omitAvatars: true))
            print(data.count)
        }
    }
    #endif
}
