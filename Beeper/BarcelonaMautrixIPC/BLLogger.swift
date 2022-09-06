//
//  BLLogger.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 5/28/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import BarcelonaFoundation

private let BLDefaultModule = ""

private extension LoggingLevel {
    var ipcLevel: IPCLoggingLevel {
        switch self {
        case .info:
            return .info
        case .warn:
            return .warn
        case .debug:
            return .debug
        case .fault:
            return .fatal
        case .error:
            return .error
        }
    }
}

public class BLMautrixSTDOutDriver: LoggingDriver {
    public static let shared = BLMautrixSTDOutDriver()
    
    private init() {}
    
    public func log(level: LoggingLevel, fileID: StaticString, line: Int, function: StaticString, dso: UnsafeRawPointer, category: StaticString, message: StaticString, args: [CVarArg]) {
        BLWritePayload {
            $0.command = .log(.with {
                $0.level = level.ipcLevel.rawValue
                $0.module = String(category)
                $0.message = String(format: String(message), arguments: args)
                $0.metadata = [
                    "fileID": .string(fileID.description),
                    "function": .string(function.description),
                    "line": .string(line.description)
                ].pb
            })
        }
    }
    
    public func log(level: LoggingLevel, module: String, message: BackportedOSLogMessage, metadata: [String: MetadataValue]) {
        BLWritePayload {
            $0.command = .log(.with {
                $0.level = level.ipcLevel.rawValue
                $0.module = module
                $0.message = message.render(level: BLRuntimeConfiguration.privacyLevel)
                $0.metadata = metadata.pb
            })
        }
    }
    
    public func log(level: LoggingLevel, fileID: StaticString, line: Int, function: StaticString, dso: UnsafeRawPointer, category: StaticString, message: BackportedOSLogMessage, metadata: MetadataValue) {
        BLWritePayload {
            $0.command = .log(.with {
                $0.level = level.ipcLevel.rawValue
                $0.module = String(category)
                $0.message = message.render(level: BLRuntimeConfiguration.privacyLevel)
                $0.metadata = [
                    "fileID": .string(fileID.description),
                    "function": .string(function.description),
                    "line": .string(line.description)
                ].pb
            })
        }
    }
}
