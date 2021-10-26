//
//  LogCommand.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 5/28/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation

public enum IPCLoggingLevel: String, Codable {
    case debug = "DEBUG"
    case info = "INFO"
    case warn = "WARN"
    case error = "ERROR"
    case fatal = "FATAL"
}

public struct LogCommand: Encodable {
    public var level: IPCLoggingLevel
    public var module: String
    public var message: String
    public var metadata: [String: Encodable]
    
    private enum CodingKeys: String, CodingKey {
        case level, module, message, metadata
    }
    
    private struct RawCodingKey: CodingKey {
        var intValue: Int?
        
        init?(intValue: Int) {
            fatalError()
        }
        
        let stringValue: String
        
        init(stringValue: String) {
            self.stringValue = stringValue
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(level, forKey: .level)
        try container.encode(module, forKey: .module)
        try container.encode(message, forKey: .message)
        
        var metadataContainer = container.superEncoder(forKey: .metadata).container(keyedBy: RawCodingKey.self)
        
        for (key, value) in metadata {
            try value.encode(to: metadataContainer.superEncoder(forKey: .init(stringValue: key)))
        }
    }
}
