//
//  ContactResolvable.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 5/24/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import Barcelona
import Contacts
import IMCore

public protocol ContactResolvable {
    var user_guid: String { get set }
}

public extension ContactResolvable {
    var normalizedHandleID: String {
        guard user_guid.contains(";"), let last = user_guid.split(separator: ";").last else {
            return user_guid
        }
        
        return String(last)
    }
}
