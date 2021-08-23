//
//  BLRuntimeConfiguration.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 8/23/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation

private extension Optional where Wrapped == String {
    @_transparent
    private func maybe<T>(_ cb: @autoclosure () -> T?) -> T? {
        guard let _ = self else {
            return nil
        }
        
        return cb()
    }
    
    var int: Int? {
        maybe(Int(unsafelyUnwrapped))
    }
}

public final class BLRuntimeConfiguration {
    public static let healthTTL = int(forKey: "BEEPER_HEALTH_TTL", defaultValue: 240)
    public static let criticalHealthTTL = int(forKey: "BEEPER_CRITICAL_HEALTH_TTL", defaultValue: 60)
    
    private class func int(forKey key: String, defaultValue: Int) -> Int {
        ProcessInfo.processInfo.environment[key].int ?? defaultValue
    }
}
