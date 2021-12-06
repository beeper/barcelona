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

public struct ParsedGUID: Codable {
    public var service: String?
    public var style: String?
    public var last: String
    
    init(rawValue: String) {
        guard rawValue.contains(";") else {
            last = rawValue
            return
        }
        
        let split = rawValue.split(separator: ";")
        
        guard split.count == 3 else {
            last = rawValue
            return
        }
        
        service = String(split[0])
        style = String(split[1])
        last = String(split[2])
    }
}

public extension ContactResolvable {
    var normalizedHandleID: String {
        guard user_guid.contains(";"), let last = user_guid.split(separator: ";").last else {
            return user_guid
        }
        
        return String(last)
    }
}
