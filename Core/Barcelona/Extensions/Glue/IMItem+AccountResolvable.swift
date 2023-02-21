//
//  IMItem+AccountResolvable.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/3/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import IMSharedUtilities

extension IMItem {
    var imAccount: IMAccount? {
        if let accountID = accountID, let preferredAccount = IMAccountController.shared.account(forUniqueID: accountID)
        {
            return preferredAccount
        } else if let serviceID = service, let service = serviceID.service,
            let alternateAccount = IMAccountController.shared.bestAccount(forService: service)
        {
            return alternateAccount
        } else {
            return nil
        }
    }
}
