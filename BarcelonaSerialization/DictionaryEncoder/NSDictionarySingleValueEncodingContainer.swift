//
//  NSDictionarySingleValueEncodingContainer.swift
//  BarcelonaFoundation
//
//  Created by Eric Rabil on 9/29/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation

public struct NSDictionarySingleValueEncodingContainer: SingleValueEncodingContainer {
    public var codingPath: [CodingKey] {
        get {
            encoder.codingPath
        }
    }
    
    private let encoder: NSDictionaryEncoder
    private let insertionClosure: (_ value: Any) throws -> ()
    
    init(referencing encoder: NSDictionaryEncoder, insertionClosure: @escaping (_ value: Any) throws -> ()) {
        self.encoder = encoder
        self.insertionClosure = insertionClosure
    }
    
    public mutating func encodeNil() throws {
        try insertionClosure(NSNull())
    }
    
    public mutating func encode(_ value: Bool) throws {
        try insertionClosure(value)
    }
    
    public mutating func encode(_ value: String) throws {
        try insertionClosure(value)
    }
    
    public mutating func encode(_ value: Double) throws {
        try insertionClosure(value)
    }
    
    public mutating func encode(_ value: Float) throws {
        try insertionClosure(value)
    }
    
    public mutating func encode(_ value: Int) throws {
        try insertionClosure(value)
    }
    
    public mutating func encode(_ value: Int8) throws {
        try insertionClosure(value)
    }
    
    public mutating func encode(_ value: Int16) throws {
        try insertionClosure(value)
    }
    
    public mutating func encode(_ value: Int32) throws {
        try insertionClosure(value)
    }
    
    public mutating func encode(_ value: Int64) throws {
        try insertionClosure(value)
    }
    
    public mutating func encode(_ value: UInt) throws {
        try insertionClosure(value)
    }
    
    public mutating func encode(_ value: UInt8) throws {
        try insertionClosure(value)
    }
    
    public mutating func encode(_ value: UInt16) throws {
        try insertionClosure(value)
    }
    
    public mutating func encode(_ value: UInt32) throws {
        try insertionClosure(value)
    }
    
    public mutating func encode(_ value: UInt64) throws {
        try insertionClosure(value)
    }
    
    public mutating func encode<T>(_ value: T) throws where T : Encodable {
        let object = try NSDictionaryEncoder.encode(value, at: encoder.codingPath)
        try insertionClosure(object)
    }
}
