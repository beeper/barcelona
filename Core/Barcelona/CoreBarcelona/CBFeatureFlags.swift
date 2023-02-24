//
//  CBFeatureFlags.swift
//  Barcelona
//
//  Created by Eric Rabil on 1/11/22.
//

import FeatureFlags
import Foundation

#if DEBUG
private let isDebugBuild = true
#else
private let isDebugBuild = false
#endif

// to enable something off by default, --enable-
// to disable, --disable-
public class _CBFeatureFlags: FlagProvider {
    // Supported way of overriding defaults, manipulate this early on since things are cached agressively
    public struct Defaults {
        public static var adHocRichLinks: Bool = true
    }
    public let suiteName = "com.ericrabil.barcelona"

    @FeatureFlag("blocklist", defaultValue: true)
    public var enableBlocklist: Bool

    @FeatureFlag("media-monitor-timeout", defaultValue: true)
    public var mediaMonitorTimeout: Bool

    @FeatureFlag("beeper", defaultValue: false)
    public var beeper: Bool

    @FeatureFlag("migrated-database", defaultValue: false)
    public var migratedDatabase: Bool
}

extension String {
    var splitByCamel: [String] {
        unicodeScalars.reduce(into: [""]) { accumulator, character in
            if CharacterSet.uppercaseLetters.contains(character) {
                accumulator.append(String(character).lowercased())
            } else {
                accumulator[accumulator.index(before: accumulator.endIndex)].append(String(character))
            }
        }
    }

    var camelToHyphen: String {
        splitByCamel.joined(separator: "-")
    }
}

@dynamicMemberLookup
public class _CBLoggingFlags: FlagProvider {
    private var cache: [String: FeatureFlag] = [:]

    public let suiteName = "com.ericrabil.barcelona.logging"

    private func flag(dynamicMember: String) -> FeatureFlag {
        if _slowPath(!cache.keys.contains(dynamicMember)) {
            let flag = FeatureFlag(dynamicMember.camelToHyphen, domain: .feature, defaultValue: false)
            cache[dynamicMember] = flag
            return flag
        }
        return cache[dynamicMember]!
    }

    public subscript(dynamicMember dynamicMember: String) -> Bool {
        flag(dynamicMember: dynamicMember).value(inSuite: suiteName)
    }
}

public let CBFeatureFlags = _CBFeatureFlags()
public let CBLoggingFlags = _CBLoggingFlags()

@_transparent internal func ifDebugBuild(_ block: () -> Void) {
    #if DEBUG
    block()
    #endif
}

@_transparent internal func ifReleaseBuild(_ block: () -> Void) {
    #if !DEBUG
    block()
    #endif
}
