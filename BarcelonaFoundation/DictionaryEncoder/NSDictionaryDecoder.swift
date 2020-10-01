//
//  NSDictionaryDecoder.swift
//  BarcelonaFoundation
//
//  Created by Eric Rabil on 9/29/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation

public class NSDictionaryDecoder: Decoder {
    public var codingPath: [CodingKey]
    public var userInfo: [CodingUserInfoKey : Any] = [:]
    
    private let underlyingObject: Any
    
    public init(withUnderlyingObject object: Any, at codingPath: [CodingKey] = []) {
        self.underlyingObject = object
        self.codingPath = codingPath
    }
    
    public func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        let container = try NSDictionaryKeyedDecodingContainer<Key>(referencing: self, wrapping: underlyingObject as! NSDictionary)
        return KeyedDecodingContainer(container)
    }
    
    public func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        NSDictionaryUnkeyedDecodingContainer(referencing: self, wrapping: underlyingObject as! NSArray)
    }
    
    public func singleValueContainer() throws -> SingleValueDecodingContainer {
        NSDictionarySingleValueDecodingContainer(referencing: self, wrapped: underlyingObject)
    }
    
    public static func decode<T: Decodable>(_ type: T.Type, value: NSDictionary) throws -> T {
        return try T(from: NSDictionaryDecoder(withUnderlyingObject: value))
    }
}
