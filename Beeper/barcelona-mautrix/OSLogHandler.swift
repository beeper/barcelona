//
//  OSLogHandler.swift
//  Barcelona
//
//  Created by Joonas Myhrberg on 2.3.2023.
//

import Foundation
import Logging
import os

import struct Logging.Logger

struct OSLogHandler: LogHandler {

    // MARK: - Properties

    var metadata: Logging.Logger.Metadata = Logger.Metadata()
    var logLevel: Logging.Logger.Level = .debug

    private static let logSystemLogger = OSLog(subsystem: "com.beeper.barcelona-mautrix", category: "OSLogHandler")

    private let logger: OSLog
    private let jsonEncoder = JSONEncoder()

    // MARK: - Subscript

    subscript(metadataKey metadataKey: String) -> Logging.Logger.Metadata.Value? {
        get {
            return self.metadata[metadataKey]
        }
        set {
            self.metadata[metadataKey] = newValue
        }
    }

    init(label: String) {
        logger = OSLog(subsystem: "com.beeper.barcelona-mautrix", category: label)
    }

    // MARK: - Methods

    func log(
        level: Logger.Level,
        message: Logger.Message,
        metadata: Logger.Metadata?,
        source: String,
        file: String,
        function: String,
        line: UInt
    ) {
        let log: [String: String] = [
            "message": message.description,
            "source": source,
            "file": file,
            "function": function,
            "line": "\(line)",
        ]
        let level = osLogLevel(from: level)

        do {
            let logString = String(data: try jsonEncoder.encode(log), encoding: .utf8)!
            os_log("%{public}@", log: logger, type: level, logString as NSString)
        } catch {
            os_log("failed to encode log: %{public}@", log: logger, type: .error, log.debugDescription)
        }
    }

    private func osLogLevel(from logLevel: Logger.Level) -> OSLogType {
        switch logLevel {
        case .trace:
            return .debug
        case .debug:
            return .debug
        case .info:
            return .info
        case .notice:
            return .default
        case .warning:
            return .info
        case .error:
            return .error
        case .critical:
            return .fault
        }
    }
}
