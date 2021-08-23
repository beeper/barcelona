//
//  BLHandlePayload.swift
//  BarcelonaFoundation
//
//  Created by Eric Rabil on 8/23/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import Barcelona
import IMCore
import Swog

internal let IPCLog = Logger(category: "BLIPC")

public func BLHandlePayload(_ payload: IPCPayload) {
    switch payload.command {
    case let runnable as Runnable:
        runnable.run(payload: payload)
    default:
        IPCLog.warn("Received unhandleable payload type %@", payload.command.name.rawValue)
    }
}
