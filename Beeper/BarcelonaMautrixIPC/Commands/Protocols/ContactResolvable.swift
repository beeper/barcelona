//
//  ContactResolvable.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 5/24/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import Barcelona
import IMCore

struct ParsedGUID: Codable, CustomStringConvertible {
    var service: String?
    var style: String?
    var last: String
    
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
    
    var description: String {
        guard let service = service, let style = style else {
            return last
        }
        return "\(service);\(style);\(last)"
    }
}
