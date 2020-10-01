//
//  DictionaryKeyedEncodingContainer.swift
//  BarcelonaFoundation
//
//  Created by Eric Rabil on 9/29/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation

public struct NSDictionaryKeyedEncodingContainer<K: CodingKey>: KeyedEncodingContainerProtocol {
    internal init(codingPath: [CodingKey], encoder: NSDictionaryEncoder, underlyingDictionary: NSMutableDictionary) {
        self.codingPath = codingPath
        self.encoder = encoder
        self.underlyingDictionary = underlyingDictionary
    }
    
    public var codingPath: [CodingKey]
    
    public typealias Key = K
    
    // MARK: - Properties

    /// A reference to the encoder we're writing to.
    private let encoder: NSDictionaryEncoder
    
    private let underlyingDictionary: NSMutableDictionary
    
    public mutating func encodeNil(forKey key: K) throws {
        updatePath(key)
        underlyingDictionary[key.stringValue] = nil
    }
    
    public mutating func encode(_ value: Bool, forKey key: K) throws {
        updatePath(key)
        underlyingDictionary[key.stringValue] = value
    }
    
    public mutating func encode(_ value: String, forKey key: K) throws {
        updatePath(key)
        underlyingDictionary[key.stringValue] = value
    }
    
    public mutating func encode(_ value: Double, forKey key: K) throws {
        updatePath(key)
        underlyingDictionary[key.stringValue] = value
    }
    
    public mutating func encode(_ value: Float, forKey key: K) throws {
        updatePath(key)
        underlyingDictionary[key.stringValue] = value
    }
    
    public mutating func encode(_ value: Int, forKey key: K) throws {
        updatePath(key)
        underlyingDictionary[key.stringValue] = value
    }
    
    public mutating func encode(_ value: Int8, forKey key: K) throws {
        updatePath(key)
        underlyingDictionary[key.stringValue] = value
    }
    
    public mutating func encode(_ value: Int16, forKey key: K) throws {
        updatePath(key)
        underlyingDictionary[key.stringValue] = value
    }
    
    public mutating func encode(_ value: Int32, forKey key: K) throws {
        updatePath(key)
        underlyingDictionary[key.stringValue] = value
    }
    
    public mutating func encode(_ value: Int64, forKey key: K) throws {
        updatePath(key)
        underlyingDictionary[key.stringValue] = value
    }
    
    public mutating func encode(_ value: UInt, forKey key: K) throws {
        updatePath(key)
        underlyingDictionary[key.stringValue] = value
    }
    
    public mutating func encode(_ value: UInt8, forKey key: K) throws {
        updatePath(key)
        underlyingDictionary[key.stringValue] = value
    }
    
    public mutating func encode(_ value: UInt16, forKey key: K) throws {
        updatePath(key)
        underlyingDictionary[key.stringValue] = value
    }
    
    public mutating func encode(_ value: UInt32, forKey key: K) throws {
        updatePath(key)
        underlyingDictionary[key.stringValue] = value
    }
    
    public mutating func encode(_ value: UInt64, forKey key: K) throws {
        updatePath(key)
        underlyingDictionary[key.stringValue] = value
    }
    
    public mutating func encode<T>(_ value: T, forKey key: K) throws where T : Encodable {
        updatePath(key)
        
        do {
            let dict = try NSDictionaryEncoder.encode(value, at: self.encoder.codingPath)
            underlyingDictionary[key.stringValue] = dict
        } catch let error as EncodingError {
            throw error
        } catch {
            throw XPCEncodingHelpers.makeEncodingError(value, self.codingPath, String(describing: error))
        }
    }
    
    public mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: K) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        updatePath(key)
        
        let dictionary = NSMutableDictionary()
        underlyingDictionary[key] = dictionary
        let container = NSDictionaryKeyedEncodingContainer<NestedKey>(codingPath: [], encoder: self.encoder, underlyingDictionary: dictionary)
        
        return KeyedEncodingContainer(container)
    }
    
    public mutating func nestedUnkeyedContainer(forKey key: K) -> UnkeyedEncodingContainer {
        updatePath(key)
        
        let array = NSMutableArray()
        underlyingDictionary[key.stringValue] = array
        return NSDictionaryUnkeyedEncodingContainer(encoder: self.encoder, underlyingArray: array)
    }
    
    public mutating func superEncoder() -> Encoder {
        superEncoder(forCodingKey: XPCCodingKey.superKey)
    }
    
    public mutating func superEncoder(forKey key: K) -> Encoder {
        superEncoder(forCodingKey: key)
    }
    
    private mutating func superEncoder(forCodingKey key: CodingKey) -> Encoder {
        updatePath(key)
        return NSDictionaryReferencingEncoder(at: encoder.codingPath, wrapping: underlyingDictionary, forKey: key)
    }
    
    private mutating func updatePath(_ key: CodingKey) {
        self.encoder.codingPath.append(key)
        do { self.encoder.codingPath.removeLast() }
    }
}

private class NSDictionaryReferencingEncoder: NSDictionaryEncoder {
    let dictionary: NSMutableDictionary
    let key: CodingKey
    
    init(at codingPath: [CodingKey], wrapping dictionary: NSMutableDictionary, forKey key: CodingKey) {
        self.dictionary = dictionary
        self.key = key
        super.init(at: codingPath)
    }
    
    override func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        let newDictionary = NSMutableDictionary()
        dictionary[key.stringValue] = newDictionary

        // It is OK to force this through because we are explicitly passing a dictionary
        let container = NSDictionaryKeyedEncodingContainer<Key>(codingPath: [], encoder: self, underlyingDictionary: newDictionary)
        return KeyedEncodingContainer(container)
    }

    override func unkeyedContainer() -> UnkeyedEncodingContainer {
        let newArray = NSMutableArray()
        dictionary[key.stringValue] = newArray
        
        // It is OK to force this through because we are explicitly passing an array
        return NSDictionaryUnkeyedEncodingContainer(encoder: self, underlyingArray: newArray)
    }

    override func singleValueContainer() -> SingleValueEncodingContainer {
        // It is OK to force this through because we are explicitly passing a dictionary
        return NSDictionarySingleValueEncodingContainer(referencing: self, insertionClosure: {
            value in
            self.dictionary[self.key.stringValue] = value
        })
    }
}
