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
import IMFoundation

public struct BulkHandleRepresentation: Codable {
    public init(_ handles: [IMHandle]) {
        self.handles = handles.map {
            Handle($0)
        }
    }
    
    public var handles: [Handle]
}

public protocol BulkHandleIDRepresentable {
    var handles: [String] { get set }
}

public struct BulkHandleIDRepresentation: Codable, BulkHandleIDRepresentable {
    public init(handles: [String]) {
        self.handles = handles
    }
    
    public var handles: [String]
}

public struct Handle: Codable, Equatable {
    public static func == (lhs: Handle, rhs: Handle) -> Bool {
        return lhs.id == rhs.id
    }
    
    public static func === (lhs: Handle, rhs: Handle) -> Bool {
        return lhs.id == rhs.id
    }
    
    init(_ handle: IMHandle) {
        id = handle.id
        format = id.style
    }
    
    init(id: String, isBusiness: Bool) {
        self.id = id
        self.format = id.style
    }
    
    var id: String
    var format: HandleIDStyle
}
