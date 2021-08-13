//
//  IPC.swift
//  BarcelonaJS
//
//  Created by Eric Rabil on 8/12/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import BarcelonaIPC
import BarcelonaFoundation
import JavaScriptCore

public enum BarcelonaJSIPCPayloadType: UInt, Codable {
    case execute = 0
    case result = 1
    case log = 2
    case autocomplete = 4
}

internal struct LoggingPayload: Codable {
    let level: LoggingLevel
    let message: String
    let category: String
}
