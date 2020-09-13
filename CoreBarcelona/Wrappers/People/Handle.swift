//
//  Handle.swift
//  imcore-rest
//
//  Created by Eric Rabil on 7/24/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import Contacts
import IMCore

struct BulkHandleRepresentation: Codable {
    init(_ handles: [IMHandle]) {
        self.handles = handles.map {
            Handle($0)
        }
    }
    
    var handles: [Handle]
}

struct Handle: Codable, Equatable {
    static func == (lhs: Handle, rhs: Handle) -> Bool {
        return lhs.id == rhs.id
    }
    
    static func === (lhs: Handle, rhs: Handle) -> Bool {
        return lhs.id == rhs.id
    }
    
    init(_ handle: IMHandle) {
        id = handle.id
        isBusiness = handle.isBusiness()
    }
    
    init(id: String, isBusiness: Bool) {
        self.id = id
        self.isBusiness = isBusiness
    }
    
    var id: String
    var isBusiness: Bool
}
