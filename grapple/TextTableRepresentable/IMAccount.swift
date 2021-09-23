//
//  IMAccount.swift
//  grapple
//
//  Created by Eric Rabil on 8/9/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import SwiftyTextTable
import IMCore

extension IMAccount: TextTableRepresentable {
    public static var columnHeaders: [String] {
        ["service", "uniqueID", "loginID", "loginHandleID", "connected", "active", "registered", "operational", "asleep"]
    }
    
    public var tableValues: [CustomStringConvertible] {
        [
            service?.id.rawValue ?? "nil",
            uniqueID ?? "nil",
            login ?? "nil",
            loginIMHandle?.id ?? "nil",
            isConnected,
            isActive,
            isRegistered,
            isOperational,
            isAsleep
        ]
    }
}
