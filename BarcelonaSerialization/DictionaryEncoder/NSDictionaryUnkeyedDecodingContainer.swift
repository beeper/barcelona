//
//  NSDictionaryUnkeyedDecodingContainer.swift
//  BarcelonaFoundation
//
//  Created by Eric Rabil on 9/29/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation

public struct NSDictionaryUnkeyedDecodingContainer: UnkeyedDecodingContainer, CoreDecoderProtocol {
    public var codingPath: [CodingKey] {
        decoder.codingPath
    }
    
    public var count: Int? {
        underlyingArray.count
    }
    
    public var isAtEnd: Bool {
        currentIndex >= count!
    }
    
    public private(set) var currentIndex: Int
    
    private let decoder: NSDictionaryDecoder
    private let underlyingArray: NSArray
    
    private var currentKey: CodingKey {
        XPCCodingKey(intValue: currentIndex)!
    }
    
    init(referencing decoder: NSDictionaryDecoder, wrapping array: NSArray) {
        self.underlyingArray = array
        self.decoder = decoder
        self.currentIndex = 0
    }
    
    public mutating func decodeNil() throws -> Bool {
        guard underlyingArray.count > currentIndex else {
            return true
        }
        
        return underlyingArray[currentIndex] is NSNull
    }
    
    public mutating func decode(_ type: Bool.Type) throws -> Bool {
        try decode(type, key: currentKey)
    }
    
    public mutating func decode(_ type: String.Type) throws -> String {
        try decode(type, key: currentKey)
    }
    
    public mutating func decode(_ type: Double.Type) throws -> Double {
        try decode(type, key: currentKey)
    }
    
    public mutating func decode(_ type: Float.Type) throws -> Float {
        try decode(type, key: currentKey)
    }
    
    public mutating func decode(_ type: Int.Type) throws -> Int {
        try decode(type, key: currentKey)
    }
    
    public mutating func decode(_ type: Int8.Type) throws -> Int8 {
        try decode(type, key: currentKey)
    }
    
    public mutating func decode(_ type: Int16.Type) throws -> Int16 {
        try decode(type, key: currentKey)
    }
    
    public mutating func decode(_ type: Int32.Type) throws -> Int32 {
        try decode(type, key: currentKey)
    }
    
    public mutating func decode(_ type: Int64.Type) throws -> Int64 {
        try decode(type, key: currentKey)
    }
    
    public mutating func decode(_ type: UInt.Type) throws -> UInt {
        try decode(type, key: currentKey)
    }
    
    public mutating func decode(_ type: UInt8.Type) throws -> UInt8 {
        try decode(type, key: currentKey)
    }
    
    public mutating func decode(_ type: UInt16.Type) throws -> UInt16 {
        try decode(type, key: currentKey)
    }
    
    public mutating func decode(_ type: UInt32.Type) throws -> UInt32 {
        try decode(type, key: currentKey)
    }
    
    public mutating func decode(_ type: UInt64.Type) throws -> UInt64 {
        try decode(type, key: currentKey)
    }
    
    public mutating func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        try assertNotCorrupted()
        
        updatePath(currentKey)
        
        let value = try getObject(for: currentKey)
        
        let constructedValue = try T(from: NSDictionaryDecoder(withUnderlyingObject: value, at: decoder.codingPath))
        uptick()
        return constructedValue
    }
    
    public mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        try assertNotCorrupted()
        
        updatePath(currentKey)
        
        let value = try decode(NSDictionary.self, key: currentKey)
        
        let container = try NSDictionaryKeyedDecodingContainer<NestedKey>(referencing: self.decoder, wrapping: value)
        
        uptick()
        
        return KeyedDecodingContainer(container)
    }
    
    public mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        try assertNotCorrupted()
        
        updatePath(currentKey)
        
        let value = try decode(NSArray.self, key: currentKey)
        
        uptick()
        
        return NSDictionaryUnkeyedDecodingContainer(referencing: self.decoder, wrapping: value)
    }
    
    public mutating func superDecoder() throws -> Decoder {
        try assertNotCorrupted()
        
        updatePath(currentKey)
        
        let value = try getObject(for: currentKey)
        currentIndex += 1
        return NSDictionaryDecoder(withUnderlyingObject: value, at: decoder.codingPath)
    }
    
    private func assertNotCorrupted() throws {
        guard !self.isAtEnd else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath,
                                                                    debugDescription: "Reached end of unkeyed container."))
        }
    }
    
    private mutating func uptick() {
        currentIndex += 1
    }
    
    func updatePath(_ key: CodingKey) {
        decoder.codingPath.append(XPCCodingKey(intValue: currentIndex)!)
        do { decoder.codingPath.removeLast() }
    }
    
    func getObject(for key: CodingKey) throws -> Any {
        guard let index = key.intValue, underlyingArray.count > index, !(underlyingArray[index] is NSNull) else {
            throw DecodingError.keyNotFound(key,
                                            DecodingError.Context(
                                              codingPath: self.codingPath,
                                              debugDescription: "Could not find key \(key.stringValue)"))
        }

        return underlyingArray[index]
    }
}
