// Sources/CodableXPC/XPCCodingKey.swift - CodingKey Implementation for XPC
//
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// -----------------------------------------------------------------------------
//
// This file degines a coding key specific for supporting XPC. This mainly used
// for the super key.
//
// -----------------------------------------------------------------------------

import Foundation

public struct XPCCodingKey: CodingKey {
    public let stringValue: String

    public init?(stringValue: String) {
        self.intValue = nil
        self.stringValue = stringValue
    }

    public let intValue: Int?

    public init?(intValue: Int) {
        self.intValue = intValue
        self.stringValue = String(intValue)
    }

    public init(intValue: Int, stringValue: String) {
        self.intValue = intValue
        self.stringValue = stringValue
    }

    internal static let superKey = XPCCodingKey(intValue: 0, stringValue: "super")
}
