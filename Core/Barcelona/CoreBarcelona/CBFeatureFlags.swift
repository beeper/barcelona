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

private func debugOption(named name: String, defaultValue: Bool) -> Bool {
#if !DEBUG
return false
#else
return option(named: name, defaultValue: defaultValue)
#endif
}

@propertyWrapper
public struct FeatureFlag: Hashable {
    public var wrappedValue: Bool {
        get {
            domain.boolean(forFlag: self)
        }
        set {
            domain.setBoolean(newValue, forFlag: self)
        }
    }
    
    public let key: String
    public let domain: FlagDomain
    public let defaultValue: Bool
    
    public enum FlagDomain: String, Hashable, CaseIterable {
        private class NSObserver: NSObject {
            typealias Callback = (String?, Any?, [NSKeyValueChangeKey: Any]?) -> ()
            var callback: Callback
            
            init(_ callback: @escaping Callback) {
                self.callback = callback
            }
            
            override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
                callback(keyPath, object, change)
            }
        }
        
        private static let suite = UserDefaults(suiteName: "com.ericrabil.barcelona")!
        
        case feature = "feature-flags"
        case debugging = "debug-flags"
        
        private static let observer = NSObserver(FlagDomain.applyKVOUpdate(forKeyPath:of:change:))
        
        private static var once: () = {
            FlagDomain.allCases.forEach { domain in
                suite.addObserver(observer, forKeyPath: domain.rawValue, options: [.new], context: nil)
            }
        }()
        
        private static func applyKVOUpdate(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?) {
            guard let newValue = change?[.newKey] as? [String: Any] else {
                return
            }
            
            guard let keyPath = keyPath, let parsedDomain = FlagDomain(rawValue: keyPath) else {
                return
            }
            
            parsedDomain.applyKVOUpdate(newValue)
        }
        
        static var caches: [FlagDomain: [FeatureFlag: Bool]] = [:]
        static var flagsByDomain: [FlagDomain: [String: FeatureFlag]] = [:]
        
        fileprivate func applyKVOUpdate(_ dict: [String: Any]) {
            var domain = self
            
            domain.cache = [:]
            
            for (key, value) in dict {
                if let value = value as? Bool {
                    domain.setCachedBoolean(value, forKey: key)
                }
            }
        }
        
        private var cache: [FeatureFlag: Bool] {
            _read {
                yield FlagDomain.caches[self, default: [:]]
            }
            _modify {
                yield &FlagDomain.caches[self, default: [:]]
            }
        }
        
        private var flags: [String: FeatureFlag] {
            _read {
                yield FlagDomain.flagsByDomain[self, default: [:]]
            }
            _modify {
                yield &FlagDomain.flagsByDomain[self, default: [:]]
            }
        }
        
        private func setCachedBoolean(_ boolean: Bool, forKey key: String) {
            var domain = self
            
            guard let flag = flags[key] else {
                return
            }
            
            domain.cache[flag] = boolean
        }
        
        public func setBoolean(_ boolean: Bool, forFlag flag: FeatureFlag) {
            var container = FlagDomain.suite.dictionary(forKey: rawValue) ?? [:]
            var domain = self
            container[flag.key] = boolean
            domain.cache[flag] = boolean
            FlagDomain.suite.set(container, forKey: rawValue)
            FlagDomain.suite.synchronize()
        }
        
        public func boolean(forFlag flag: FeatureFlag) -> Bool {
            if let cachedBoolean = cache[flag] {
                return cachedBoolean
            }
            let boolean = uncachedBoolean(forFlag: flag)
            var domain = self
            domain.cache[flag] = boolean
            return boolean
        }
        
        fileprivate func notice(flag: FeatureFlag) {
            var domain = self
            domain.flags[flag.key] = flag
            _ = FlagDomain.once
        }
        
        private func uncachedBoolean(forFlag flag: FeatureFlag) -> Bool {
            let userDefaultsValue = FlagDomain.suite.dictionary(forKey: rawValue)?[flag.key] as? Bool
            
            switch self {
            case .feature:
                return option(named: flag.key, defaultValue: userDefaultsValue ?? flag.defaultValue)
            case .debugging:
                return debugOption(named: flag.key, defaultValue: userDefaultsValue ?? flag.defaultValue)
            }
        }
    }
    
    public init(_ key: String, domain: FlagDomain = .feature, defaultValue: Bool) {
        self.key = key
        self.domain = domain
        self.defaultValue = defaultValue
        
        domain.notice(flag: self)
    }
}

// to enable something off by default, --enable-
// to disable, --disable-
public struct _CBFeatureFlags: _FlagProvider {
    @FeatureFlag("matrix-audio", defaultValue: false)
    public var permitAudioOverMautrix: Bool
    
    @FeatureFlag("internal-diagnostics", defaultValue: isDebugBuild)
    public var internalDiagnostics: Bool
    
    @FeatureFlag("xcode", domain: .debugging, defaultValue: false)
    public var runningFromXcode: Bool
    
    @FeatureFlag("any-country", defaultValue: false)
    public var ignoresSameCountryCodeAssertion: Bool
    
    @FeatureFlag("scratchbox", domain: .debugging, defaultValue: false)
    public var scratchbox: Bool
    
    @FeatureFlag("exit-after-scratchbox", domain: .debugging, defaultValue: true)
    public var exitAfterScratchbox: Bool
    
    @FeatureFlag("contact-fuzz-enumerator", defaultValue: true)
    public var contactFuzzEnumerator: Bool
    
    @FeatureFlag("sms-read-buffer", defaultValue: true)
    public var useSMSReadBuffer: Bool
    
    @FeatureFlag("drop-spam-messages", defaultValue: true)
    public var dropSpamMessages: Bool
    
    @FeatureFlag("log-sensitive-payloads", defaultValue: isDebugBuild)
    public var logSensitivePayloads: Bool
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
        let loggingStatus = option(named: loggingToken, defaultValue: false)
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

@_transparent internal func ifReleaseBuild(_ block: () -> ()) {
    #if !DEBUG
    block()
    #endif
}
