//
//  CoreDecoder.swift
//  BarcelonaFoundation
//
//  Created by Eric Rabil on 9/29/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation

protocol CoreDecoderProtocol {
    var codingPath: [CodingKey] { get }
    func getObject(for key: CodingKey) throws -> Any
    func updatePath(_ key: CodingKey)
}

internal func makeTypeDecodingError(_ value: Any, at codingPath: [CodingKey], type: String) -> EncodingError {
    XPCEncodingHelpers.makeEncodingError(value, codingPath, "Invalid \(type) value")
}

internal func decodeUnknownValue<P>(_ type: P.Type, value optionalValue: Any?, at codingPath: [CodingKey]) throws -> P {
    guard let value = optionalValue, let decode = value as? P else {
        throw makeTypeDecodingError(optionalValue ?? "nil", at: codingPath, type: String(describing: type))
    }
    
    return decode
}

extension CoreDecoderProtocol {
    internal func decode<P>(_ type: P.Type, value optionalValue: Any?) throws -> P {
        try decodeUnknownValue(type, value: optionalValue, at: codingPath)
    }
    
    internal func decode<P>(_ type: P.Type, key: CodingKey) throws -> P {
        updatePath(key)
        
        return try decode(type, value: try getObject(for: key))
    }
}
