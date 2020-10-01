//
//  NSDictionarySingleValueDecodingContainer.swift
//  BarcelonaFoundation
//
//  Created by Eric Rabil on 9/29/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation

public struct NSDictionarySingleValueDecodingContainer: SingleValueDecodingContainer {
    public var codingPath: [CodingKey] {
        decoder.codingPath
    }
    
    init(referencing decoder: NSDictionaryDecoder, wrapped object: Any?) {
        self.decoder = decoder
        self.underlyingValue = object
    }
    
    public func decodeNil() -> Bool {
        underlyingValue is NSNull || underlyingValue == nil
    }
    
    public func decode(_ type: Bool.Type) throws -> Bool {
        try decodePrimitive(type)
    }
    
    public func decode(_ type: String.Type) throws -> String {
        try decodePrimitive(type)
    }
    
    public func decode(_ type: Double.Type) throws -> Double {
        try decodePrimitive(type)
    }
    
    public func decode(_ type: Float.Type) throws -> Float {
        try decodePrimitive(type)
    }
    
    public func decode(_ type: Int.Type) throws -> Int {
        try decodePrimitive(type)
    }
    
    public func decode(_ type: Int8.Type) throws -> Int8 {
        try decodePrimitive(type)
    }
    
    public func decode(_ type: Int16.Type) throws -> Int16 {
        try decodePrimitive(type)
    }
    
    public func decode(_ type: Int32.Type) throws -> Int32 {
        try decodePrimitive(type)
    }
    
    public func decode(_ type: Int64.Type) throws -> Int64 {
        try decodePrimitive(type)
    }
    
    public func decode(_ type: UInt.Type) throws -> UInt {
        try decodePrimitive(type)
    }
    
    public func decode(_ type: UInt8.Type) throws -> UInt8 {
        try decodePrimitive(type)
    }
    
    public func decode(_ type: UInt16.Type) throws -> UInt16 {
        try decodePrimitive(type)
    }
    
    public func decode(_ type: UInt32.Type) throws -> UInt32 {
        try decodePrimitive(type)
    }
    
    public func decode(_ type: UInt64.Type) throws -> UInt64 {
        try decodePrimitive(type)
    }
    
    public func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        try T(from: NSDictionaryDecoder.init(withUnderlyingObject: underlyingValue ?? NSNull(), at: codingPath))
    }
    
    private func decodePrimitive<T>(_ type: T.Type) throws -> T {
        try decodeUnknownValue(type, value: underlyingValue, at: codingPath)
    }
    
    private let decoder: NSDictionaryDecoder
    private let underlyingValue: Any?
}
