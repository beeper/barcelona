//
//  IMCore+SwiftRefinements.swift
//  Barcelona
//
//  Created by Eric Rabil on 11/2/21.
//

import Foundation
import IMCore

extension IMAccountController {
    public static var shared: IMAccountController {
        __sharedInstance()
    }

    /// Returns an iMessage account
    public var iMessageAccount: IMAccount? {
        __activeIMessageAccount
            ?? accounts.first(where: {
                $0.service?.id == .iMessage
            })
    }
}
