//
//  NSDictionaryUnkeyedEncodingContainer.swift
//  BarcelonaFoundation
//
//  Created by Eric Rabil on 9/29/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation

public struct NSDictionaryUnkeyedEncodingContainer: UnkeyedEncodingContainer {
    internal init(encoder: NSDictionaryEncoder, underlyingArray: NSMutableArray) {
        self.encoder = encoder
        self.underlyingArray = underlyingArray
    }
    
    public var codingPath: [CodingKey] {
        self.encoder.codingPath
    }
    
    public var count: Int {
        underlyingArray.count
    }
    
    private let encoder: NSDictionaryEncoder
    private let underlyingArray: NSMutableArray
    
    private func uptick() {
        self.encoder.codingPath.append(XPCCodingKey(intValue: self.count - 1)!)
        do { self.encoder.codingPath.removeLast() }
    }
    
    private mutating func add(_ value: Any) {
        uptick()
        underlyingArray.add(value)
    }
    
    public mutating func encodeNil() throws {
        add(NSNull())
    }
    
    public mutating func encode(_ value: Bool) throws {
        add(value)
    }
    
    public mutating func encode(_ value: String) throws {
        add(value)
    }
    
    public mutating func encode(_ value: Double) throws {
        add(value)
    }
    
    public mutating func encode(_ value: Float) throws {
        add(value)
    }
    
    public mutating func encode(_ value: Int) throws {
        add(value)
    }
    
    public mutating func encode(_ value: Int8) throws {
        add(value)
    }
    
    public mutating func encode(_ value: Int16) throws {
        add(value)
    }
    
    public mutating func encode(_ value: Int32) throws {
        add(value)
    }
    
    public mutating func encode(_ value: Int64) throws {
        add(value)
    }
    
    public mutating func encode(_ value: UInt) throws {
        add(value)
    }
    
    public mutating func encode(_ value: UInt8) throws {
        add(value)
    }
    
    public mutating func encode(_ value: UInt16) throws {
        add(value)
    }
    
    public mutating func encode(_ value: UInt32) throws {
        add(value)
    }
    
    public mutating func encode(_ value: UInt64) throws {
        add(value)
    }
    
    public mutating func encode<T>(_ value: T) throws where T : Encodable {
        add(value)
    }
    
    public mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        let dict = NSMutableDictionary()
        add(dict)
        
        let container = NSDictionaryKeyedEncodingContainer<NestedKey>(codingPath: [], encoder: self.encoder, underlyingDictionary: dict)
        
        return KeyedEncodingContainer(container)
    }
    
    public mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        let array = NSMutableArray()
        add(array)
        
        return NSDictionaryUnkeyedEncodingContainer(encoder: encoder, underlyingArray: array)
    }
    
    public mutating func superEncoder() -> Encoder {
        add(NSNull())
        return NSArrayReferencingEncoder(at: self.codingPath, wrapping: self.underlyingArray, forIndex: self.count - 1)
    }
}

private class NSArrayReferencingEncoder: NSDictionaryEncoder {
    let array: NSMutableArray
    let index: Int
    
    init(at codingPath: [CodingKey], wrapping array: NSMutableArray, forIndex index: Int) {
        self.array = array
        self.index = index
        super.init(at: codingPath)
    }
    
    override func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        let dict = NSMutableDictionary()
        array[index] = dict
        
        let container = NSDictionaryKeyedEncodingContainer<Key>(codingPath: [], encoder: self, underlyingDictionary: dict)
        return KeyedEncodingContainer(container)
    }
    
    override func unkeyedContainer() -> UnkeyedEncodingContainer {
        let array = NSMutableArray()
        array[index] = array
        
        return NSDictionaryUnkeyedEncodingContainer(encoder: self, underlyingArray: array)
    }
}
