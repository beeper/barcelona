//
//  TypeParser.swift
//  BarcelonaDocs
//
//  Created by Eric Rabil on 8/17/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import SwiftSyntax

public indirect enum ParsedType: Codable {
    case optional(ParsedType)
    case array(ParsedType)
    case dictionary(ParsedType, ParsedType)
    case literal(String)
    case unknown
    
    public init(rawValue: TypeSyntax) {
        if let optional = rawValue.as(OptionalTypeSyntax.self) {
            self = .optional(.init(rawValue: optional.wrappedType))
        } else if let array = rawValue.as(ArrayTypeSyntax.self) {
            self = .array(.init(rawValue: array.elementType))
        } else if let dictionary = rawValue.as(DictionaryTypeSyntax.self) {
            self = .dictionary(.init(rawValue: dictionary.keyType), .init(rawValue: dictionary.valueType))
        } else if let simpleType = rawValue.as(SimpleTypeIdentifierSyntax.self) {
            self = .literal(simpleType.name.text)
        } else {
            self = .unknown
        }
    }
    
    private enum CodingKeys: CodingKey {
        case metatype, type
    }
    
    private enum DictionaryCodingKeys: CodingKey {
        case key, value
    }
    
    private enum Metatype: String, Codable {
        case optional, array, dictionary, literal, unknown
    }
    
    private var metatype: Metatype {
        switch self {
        case .optional: return .optional
        case .array: return .array
        case .dictionary: return .dictionary
        case .literal: return .literal
        case .unknown: return .unknown
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(metatype, forKey: .metatype)
        
        switch self {
        case .optional(let type):
            fallthrough
        case .array(let type):
            try container.encode(type, forKey: .type)
        case .dictionary(let key, let value):
            var subcontainer = container.nestedContainer(keyedBy: DictionaryCodingKeys.self, forKey: .type)
            
            try subcontainer.encode(key, forKey: .key)
            try subcontainer.encode(value, forKey: .value)
        case .literal(let text):
            try container.encode(text, forKey: .type)
        case .unknown:
            try container.encodeNil(forKey: .type)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let metatype = try container.decode(Metatype.self, forKey: .metatype)
        
        switch metatype {
        case .optional:
            self = .optional(try container.decode(ParsedType.self, forKey: .type))
        case .array:
            self = .array(try container.decode(ParsedType.self, forKey: .type))
        case .dictionary:
            let subcontainer = try container.nestedContainer(keyedBy: DictionaryCodingKeys.self, forKey: .type)
            self = .dictionary(try subcontainer.decode(ParsedType.self, forKey: .key), try subcontainer.decode(ParsedType.self, forKey: .value))
        case .literal:
            self = .literal(try container.decode(String.self, forKey: .type))
        case .unknown:
            self = .unknown
        }
    }
}
