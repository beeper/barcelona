//
//  NSDictionaryKeyedDecodingContainer.swift
//  BarcelonaFoundation
//
//  Created by Eric Rabil on 9/29/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation

public struct NSDictionaryKeyedDecodingContainer<K: CodingKey>: KeyedDecodingContainerProtocol, CoreDecoderProtocol {
    
    public typealias Key = K
    private let decoder: NSDictionaryDecoder
    private let underlyingDictionary: NSDictionary
    
    public var codingPath: [CodingKey] {
        decoder.codingPath
    }
    
    public var allKeys: [K] {
        Array(underlyingDictionary.allKeys).compactMap {
            $0 as? String
        }.compactMap {
            Key(stringValue: $0)
        }
    }
    
    init(referencing decoder: NSDictionaryDecoder, wrapping underlyingDictionary: NSDictionary) throws {
        self.decoder = decoder
        self.underlyingDictionary = underlyingDictionary
    }
    
    public func contains(_ key: K) -> Bool {
        underlyingDictionary.object(forKey: key) == nil
    }
    
    func updatePath(_ key: CodingKey) {
        self.decoder.codingPath.append(key)
        do { self.decoder.codingPath.removeLast() }
    }
    
    public func decodeNil(forKey key: K) throws -> Bool {
        updatePath(key)
        return underlyingDictionary[key.stringValue] is NSNull || underlyingDictionary[key.stringValue] == nil
    }
    
    public func decode(_ type: Bool.Type, forKey key: K) throws -> Bool {
        try decode(type, key: key)
    }
    
    public func decode(_ type: String.Type, forKey key: K) throws -> String {
        try decode(type, key: key)
    }
    
    public func decode(_ type: Double.Type, forKey key: K) throws -> Double {
        try decode(type, key: key)
    }
    
    public func decode(_ type: Float.Type, forKey key: K) throws -> Float {
        try decode(type, key: key)
    }
    
    public func decode(_ type: Int.Type, forKey key: K) throws -> Int {
        try decode(type, key: key)
    }
    
    public func decode(_ type: Int8.Type, forKey key: K) throws -> Int8 {
        try decode(type, key: key)
    }
    
    public func decode(_ type: Int16.Type, forKey key: K) throws -> Int16 {
        try decode(type, key: key)
    }
    
    public func decode(_ type: Int32.Type, forKey key: K) throws -> Int32 {
        try decode(type, key: key)
    }
    
    public func decode(_ type: Int64.Type, forKey key: K) throws -> Int64 {
        try decode(type, key: key)
    }
    
    public func decode(_ type: UInt.Type, forKey key: K) throws -> UInt {
        try decode(type, key: key)
    }
    
    public func decode(_ type: UInt8.Type, forKey key: K) throws -> UInt8 {
        try decode(type, key: key)
    }
    
    public func decode(_ type: UInt16.Type, forKey key: K) throws -> UInt16 {
        try decode(type, key: key)
    }
    
    public func decode(_ type: UInt32.Type, forKey key: K) throws -> UInt32 {
        try decode(type, key: key)
    }
    
    private func decode<P>(_ type: P.Type, key: K) throws -> P {
        updatePath(key)
        
        return try decode(type, value: try getObject(for: key))
    }
    
    public func decode(_ type: UInt64.Type, forKey key: K) throws -> UInt64 {
        try decode(type, key: key)
    }
    
    public func decode<T>(_ type: T.Type, forKey key: K) throws -> T where T : Decodable {
        updatePath(key)
        
        guard let value = underlyingDictionary[key.stringValue] else {
            throw XPCEncodingHelpers.makeEncodingError(key, codingPath, "Failed to find key for decoder")
        }
        
        return try T(from: NSDictionaryDecoder(withUnderlyingObject: value, at: self.decoder.codingPath))
    }
    
    func getObject(for key: CodingKey) throws -> Any {
        guard let foundValue = underlyingDictionary[key.stringValue], !(foundValue is NSNull) else {
            throw DecodingError.keyNotFound(key,
                                            DecodingError.Context(
                                              codingPath: self.codingPath,
                                              debugDescription: "Could not find key \(key.stringValue)"))
        }

        return foundValue
    }
    
    public func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: K) throws -> KeyedDecodingContainer<NestedKey> {
        updatePath(key)
        
        let container = try NSDictionaryKeyedDecodingContainer<NestedKey>(referencing: decoder, wrapping: try decode(NSDictionary.self, key: key))
        return KeyedDecodingContainer(container)
    }
    
    public func nestedUnkeyedContainer(forKey key: K) throws -> UnkeyedDecodingContainer {
        updatePath(key)
        
        return NSDictionaryUnkeyedDecodingContainer(referencing: decoder, wrapping: try decode(NSArray.self, key: key))
    }
    
    public func superDecoder() throws -> Decoder {
        try superDecoder(forCodingKey: XPCCodingKey.superKey)
    }
    
    public func superDecoder(forKey key: K) throws -> Decoder {
        try superDecoder(forCodingKey: key)
    }
    
    private func superDecoder(forCodingKey key: CodingKey) throws -> Decoder {
        updatePath(key)
        
        let value = try getObject(for: key)
        
        return NSDictionaryDecoder(withUnderlyingObject: value, at: decoder.codingPath)
    }
}

