//
//  SentryLogHandler.swift
//  barcelona
//
//  Created by Joonas Myhrberg on 23.2.2023.
//

import Foundation
import Logging
import Sentry

struct SentryLogHandler: LogHandler {

    subscript(metadataKey metadataKey: String) -> Logging.Logger.Metadata.Value? {
        get {
            return self.metadata[metadataKey]
        }
        set {
            self.metadata[metadataKey] = newValue
        }
    }

    let label: String

    var metadata: Logging.Logger.Metadata = Logger.Metadata()

    var logLevel: Logging.Logger.Level = .debug

    func log(
        level: Logger.Level,
        message: Logger.Message,
        metadata: Logger.Metadata?,
        source: String,
        file: String,
        function: String,
        line: UInt
    ) {
        let breadcrumb = Breadcrumb(level: sentryLevel(from: logLevel), category: label)
        breadcrumb.timestamp = Date()
        breadcrumb.message = message.description
        breadcrumb.type = "debug"
        SentrySDK.addBreadcrumb(breadcrumb)
    }

    private func sentryLevel(from logLevel: Logger.Level) -> SentryLevel {
        switch logLevel {
        case .trace:
            return .debug
        case .debug:
            return .debug
        case .info:
            return .info
        case .notice:
            return .info
        case .warning:
            return .warning
        case .error:
            return .error
        case .critical:
            return .fatal
        }
    }
}
