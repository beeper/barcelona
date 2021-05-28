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

public struct LogCommand: Codable {
    public var time: Date
    public var level: IPCLoggingLevel
    public var module: String
    public var message: String
}
