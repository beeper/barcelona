//
//  Handle.swift
//  imcore-rest
//
//  Created by Eric Rabil on 7/24/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import IMFoundation

public enum HandleIDStyle: String, Codable {
    case email
    case businessID
    case phoneNumber
    case unknown
}

public struct BulkHandleIDRepresentation: Codable, Hashable {
    public init(handles: [String]) {
        self.handles = handles
    }

    public var handles: [String]
}

public struct Handle: Codable, Hashable, Equatable {
    public static func == (lhs: Handle, rhs: Handle) -> Bool {
        return lhs.id == rhs.id
    }

    public var id: String
    public var format: HandleIDStyle
}
