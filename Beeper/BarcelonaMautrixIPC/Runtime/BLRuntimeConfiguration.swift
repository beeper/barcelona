//
//  BLRuntimeConfiguration.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 8/23/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import Swog

private extension Optional where Wrapped == String {
    @_transparent
    private func maybe<T>(_ cb: @autoclosure () -> T?) -> T? {
        guard let _ = self else {
            return nil
        }
        
        return cb()
    }
    
    func assume<P: RawRepresentable>(orElse defaultValue: P) -> P where P.RawValue == String {
        guard let str = self, let value = P(rawValue: str) else {
            return defaultValue
        }
        
        return value
    }
    
    func assume<P: RawRepresentable>(orElse defaultValue: P) -> P where P.RawValue == UInt8 {
        guard let int = maybe(P.RawValue(unsafelyUnwrapped)), let value = P(rawValue: int) else {
            return defaultValue
        }
        
        return value
    }
    
    var int: Int? {
        maybe(Int(unsafelyUnwrapped))
    }
    
    var bool: Bool? {
        maybe(Bool(unsafelyUnwrapped))
    }
}

internal enum OSLogPrivacyConfiguration: String {
    case auto
    case `public`
    case `private`
    
    var privacy: BackportedOSLogPrivacy {
        switch self {
        case .auto:
            return .auto
        case .public:
            return .public
        case .private:
            return .private
        }
    }
}

public final class BLRuntimeConfiguration {
    public static let healthTTL = int(forKey: "BEEPER_HEALTH_TTL", defaultValue: 240)
    public static let criticalHealthTTL = int(forKey: "BEEPER_CRITICAL_HEALTH_TTL", defaultValue: 60)
    public static let loggingLevel: LoggingLevel = assume(forKey: "BARCELONA_LOGGING_LEVEL", defaultValue: .debug)
    public static let privacyLevel: BackportedOSLogPrivacy = assume(forKey: "BARCELONA_PRIVACY_LEVEL", defaultValue: OSLogPrivacyConfiguration.auto).privacy
    public static let jsIPC: Bool = bool(forKey: "BARCELONA_JS_IPC", defaultValue: false)
    
    private class func assume<P: RawRepresentable>(forKey key: String, defaultValue: P) -> P where P.RawValue == String {
        ProcessInfo.processInfo.environment[key].assume(orElse: defaultValue)
    }
    
    private class func assume<P: RawRepresentable>(forKey key: String, defaultValue: P) -> P where P.RawValue == UInt8 {
        ProcessInfo.processInfo.environment[key].assume(orElse: defaultValue)
    }
    
    private class func int(forKey key: String, defaultValue: Int) -> Int {
        ProcessInfo.processInfo.environment[key].int ?? defaultValue
    }
    
    private class func bool(forKey key: String, defaultValue: Bool) -> Bool {
        ProcessInfo.processInfo.environment[key].bool ?? defaultValue
    }
}
