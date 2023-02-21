//
//  BLUnitTests.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 2/9/22.
//

import Foundation

class BLUnitTests {
    static let shared = BLUnitTests()

    enum ForcedCondition {
        case messageFailure
    }

    var forcedConditions: Set<ForcedCondition> = Set()

    init() {
        if ProcessInfo.processInfo.environment.keys.contains("BL_FORCE_MESSAGE_FAILURE") {
            forcedConditions.insert(.messageFailure)
        }
    }
}
