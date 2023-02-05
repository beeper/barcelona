//
//  BLLogger.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 5/28/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import BarcelonaFoundation

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
    private let ipcChannel: MautrixIPCChannel
    
    public init(ipcChannel: MautrixIPCChannel) {
        self.ipcChannel = ipcChannel
    }
    
    public func log(level: LoggingLevel, fileID: StaticString, line: Int, function: StaticString, dso: UnsafeRawPointer, category: StaticString, message: StaticString, args: [CVarArg]) {
        self.ipcChannel.writePayload(.init(id: nil, command: .log(LogCommand(level: level.ipcLevel, module: String(category), message: String(format: String(message), arguments: args), metadata: [
            "fileID": fileID.description,
            "function": function.description,
            "line": line.description
        ]))), log: false)
    }

    public func log(level: LoggingLevel, fileID: StaticString, line: Int, function: StaticString, dso: UnsafeRawPointer, category: StaticString, message: BackportedOSLogMessage, metadata: MetadataValue) {
        self.ipcChannel.writePayload(.init(id: nil, command: .log(LogCommand(level: level.ipcLevel, module: String(category), message: message.render(level: BLRuntimeConfiguration.privacyLevel), metadata: [
            "fileID": fileID.description,
            "function": function.description,
            "line": line.description
        ]))), log: false)
    }
}
