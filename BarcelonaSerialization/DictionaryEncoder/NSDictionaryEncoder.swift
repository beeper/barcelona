//
//  DictionaryEncoder.swift
//  BarcelonaFoundation
//
//  Created by Eric Rabil on 9/29/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation

public class NSDictionaryEncoder: Encoder {
    public var codingPath: [CodingKey]
    public var userInfo: [CodingUserInfoKey : Any] = [:]
    private var containerKind: XPCEncoder.ContainerKind = .noContainer
    
    var topLevelContainer: Any?
    
    public init(at codingPath: [CodingKey]) {
        self.codingPath = codingPath
    }
    
    public func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        switch containerKind {
        case .noContainer:
            self.topLevelContainer = NSMutableDictionary()
            self.containerKind = .keyed
        case .keyed:
            break
        default:
            preconditionFailure("This encoder already has a container of kind \(self.containerKind)")
        }
        
        let container = NSDictionaryKeyedEncodingContainer<Key>(codingPath: [], encoder: self, underlyingDictionary: topLevelContainer as! NSMutableDictionary)
        return KeyedEncodingContainer(container)
    }
    
    public func unkeyedContainer() -> UnkeyedEncodingContainer {
        switch containerKind {
        case .noContainer:
            self.topLevelContainer = NSMutableArray()
            self.containerKind = .unkeyed
        case .unkeyed:
            break
        default:
            preconditionFailure("This encoder already has a container of kind \(self.containerKind)")
        }
        
        return NSDictionaryUnkeyedEncodingContainer(encoder: self, underlyingArray: topLevelContainer as! NSMutableArray)
    }
    
    public func singleValueContainer() -> SingleValueEncodingContainer {
        switch containerKind {
        case .noContainer:
            self.containerKind = .singleValue
        default:
            preconditionFailure("This encoder already has a container of kind \(self.containerKind)")
        }

        return NSDictionarySingleValueEncodingContainer(referencing: self, insertionClosure: {
            self.topLevelContainer = $0
        })
    }
    
    public static func encode<T: Encodable>(_ value: T, at codingPath: [CodingKey] = []) throws -> NSDictionary {
        let encoder = NSDictionaryEncoder(at: codingPath)
        
        try value.encode(to: encoder)
        
        return encoder.topLevelContainer as! NSDictionary
    }
}
