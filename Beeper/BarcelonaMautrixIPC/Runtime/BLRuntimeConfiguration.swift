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

    func assume<P: RawRepresentable>(orElse defaultValue: P) -> P where P.RawValue == String {
        guard let str = self, let value = P(rawValue: str) else {
            return defaultValue
        }
        
        return value
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

final class BLRuntimeConfiguration {
    static let privacyLevel: BackportedOSLogPrivacy = assume(forKey: "BARCELONA_PRIVACY_LEVEL", defaultValue: OSLogPrivacyConfiguration.auto).privacy
    
    private class func assume<P: RawRepresentable>(forKey key: String, defaultValue: P) -> P where P.RawValue == String {
        ProcessInfo.processInfo.environment[key].assume(orElse: defaultValue)
    }
}
