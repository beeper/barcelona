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

public enum HandleIDStyle: String, Codable {
    case email
    case businessID
    case phoneNumber
    case unknown
}

public struct BulkHandleRepresentation: Codable {
    public init(_ handles: [IMHandle]) {
        self.handles = handles.map(Handle.init)
    }
    
    public var handles: [Handle]
}

public protocol BulkHandleIDRepresentable {
    var handles: [String] { get set }
}

public struct BulkHandleIDRepresentation: Codable, Hashable, BulkHandleIDRepresentable {
    public init(handles: [String]) {
        self.handles = handles
    }
    
    public var handles: [String]
}

public struct Handle: Codable, Hashable, Equatable {
    public static func == (lhs: Handle, rhs: Handle) -> Bool {
        return lhs.id == rhs.id
    }
    
    public static func === (lhs: Handle, rhs: Handle) -> Bool {
        return lhs.id == rhs.id
    }
    
    public init(_ handle: IMHandle) {
        id = handle.id
        format = id.style
    }
    
    public init(id: String) {
        self.id = id
        self.format = id.style
    }
    
    public var id: String
    public var format: HandleIDStyle
}

public extension Handle {
    var contact: Contact? {
        for handle in IMHandleRegistrar.sharedInstance().getIMHandles(forID: id) {
            if let contact = handle.cnContact {
                return Contact(contact)
            }
        }
        
        return nil
    }
}
