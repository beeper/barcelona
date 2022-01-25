//
//  CBFeatureFlags.swift
//  Barcelona
//
//  Created by Eric Rabil on 1/11/22.
//

import Foundation

#if DEBUG
private let isDebugBuild = true
#else
private let isDebugBuild = false
#endif

private func checkArguments(_ name: String, defaultValue: Bool, insertEnablePrefix: Bool = true) -> Bool {
    if ProcessInfo.processInfo.arguments.contains("--disable-" + name) {
        return false
    } else if ProcessInfo.processInfo.arguments.contains(insertEnablePrefix ? "--enable-" + name : name) {
        return true
    } else {
        return defaultValue
    }
}

private func option(named name: String, defaultValue: Bool, aliases: [String] = []) -> Bool {
    checkArguments(name, defaultValue: defaultValue) || aliases.contains(where: { alias in
        checkArguments(alias, defaultValue: defaultValue, insertEnablePrefix: false)
    })
}

/// These options will always be false in production builds (things here are highly unstable and shouldn't even be contemplated by the end user)
private func debugOption(named name: String, defaultValue: Bool) -> Bool {
    #if !DEBUG
    return false
    #else
    return option(named: name, defaultValue: defaultValue)
    #endif
}

@_marker
public protocol _FlagProvider {}

public extension _FlagProvider {
    @inlinable @inline(__always) func `if`(_ keyPath: KeyPath<Self, Bool>, _ expr: @autoclosure () -> ()) {
        guard self[keyPath: keyPath] else {
            return
        }
        expr()
    }
    
    @inlinable @inline(__always) func `if`<P>(_ keyPath: KeyPath<Self, Bool>, _ expr: @autoclosure () -> P, or: P) -> P {
        guard self[keyPath: keyPath] else {
            return or
        }
        return expr()
    }
    
    @inlinable @inline(__always) func ifNot<P>(_ keyPath: KeyPath<Self, Bool>, _ expr: @autoclosure () -> P, else: P) -> P {
        guard !self[keyPath: keyPath] else {
            return `else`
        }
        return expr()
    }
}

// to enable something off by default, --enable-
// to disable, --disable-
public struct _CBFeatureFlags: _FlagProvider {
    public let permitInvalidAudioMessages = option(named: "amr-validation", defaultValue: true)
    public let performAMRTranscoding = option(named: "amr-transcoding", defaultValue: false)
    public let permitAudioOverMautrix = debugOption(named: "matrix-audio", defaultValue: false)
    public let internalDiagnostics = option(named: "internal-diagnostics", defaultValue: isDebugBuild)
    public let runningFromXcode = debugOption(named: "xcode", defaultValue: false)
    public let ignoresSameCountryCodeAssertion = debugOption(named: "any-country", defaultValue: false)
    public let scratchbox = debugOption(named: "scratchbox", defaultValue: false)
    public let exitAfterScratchbox = debugOption(named: "exit-after-scratchbox", defaultValue: true)
    public let contactFuzzEnumerator = option(named: "contact-fuzz-enumerator", defaultValue: true)
    public let useSMSReadBuffer = option(named: "sms-read-buffer", defaultValue: true)
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
public struct _CBLoggingFlags: _FlagProvider {
    private static var cache: [String: Bool] = [:]
    
    public subscript(dynamicMember dynamicMember: String) -> Bool {
        if let cachedValue = Self.cache[dynamicMember] {
            return cachedValue
        }
        let loggingToken = dynamicMember.camelToHyphen.appending("-logging")
        let loggingStatus = option(named: loggingToken, defaultValue: isDebugBuild)
        Self.cache[dynamicMember] = loggingStatus
        return loggingStatus
    }
}

public let CBFeatureFlags = _CBFeatureFlags()
public let CBLoggingFlags = _CBLoggingFlags()

@_transparent internal func ifInternal(_ block: () -> ()) {
    if CBFeatureFlags.internalDiagnostics {
        block()
    }
}

@_transparent internal func ifDebugBuild(_ block: () -> ()) {
    #if DEBUG
    block()
    #endif
}
