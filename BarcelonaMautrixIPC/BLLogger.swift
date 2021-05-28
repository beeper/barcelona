//
//  BLLogger.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 5/28/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation

private let BLDefaultModule = ""

public func BLLog(_ str: String, level: IPCLoggingLevel = .info, module: String? = nil, _ fmt: CVarArg...) {
    BLWritePayload(.init(id: -1, command: .log(LogCommand(time: .init(), level: level, module: module ?? BLDefaultModule, message: String(format: str, fmt)))))
}

public func BLDebug(_ str: String, module: String? = nil, _ fmt: CVarArg...) {
    BLLog(str, level: .debug, module: module, fmt)
}

public func BLInfo(_ str: String, module: String? = nil, _ fmt: CVarArg...) {
    BLLog(str, level: .info, module: module, fmt)
}

public func BLWarn(_ str: String, module: String? = nil, _ fmt: CVarArg...) {
    BLLog(str, level: .warn, module: module, fmt)
}

public func BLError(_ str: String, module: String? = nil, _ fmt: CVarArg...) {
    BLLog(str, level: .error, module: module, fmt)
}

public func BLFatal(_ str: String, module: String? = nil, _ fmt: CVarArg...) {
    BLLog(str, level: .fatal, module: module, fmt)
}
