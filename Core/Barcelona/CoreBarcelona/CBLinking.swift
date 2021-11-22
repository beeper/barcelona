//
//  CBLinking.swift
//  Barcelona
//
//  Swift's availability system is too unpredictable and limited
//
//  Created by Eric Rabil on 11/3/21.
//

import Foundation
import Swog

private let log = Logger(category: "CBLinking")

/// A constraint that will either qualify or disqualify a symbol from being selected during reconciliation
public enum CBLinkerConstraint: Hashable, Equatable, CustomDebugStringConvertible {
    /// before macOS 12, iOS 15, watchOS 8
    case preMonterey
    /// macOS 12, iOS 15, watchOS 8
    case monterey
    /// before macOS 11, iOS 14, watchOS 7
    case preBigSur
    /// macOS 11, iOS 14, watchOS 7
    case bigSur
    
    /// Whether the current environment satisfies the constraint
    public var applies: Bool {
        switch self {
        case .preMonterey:
            if #available(macOS 12, iOS 15, watchOS 8, *) {
                return false
            } else {
                return true
            }
        case .monterey:
            if #available(macOS 12, iOS 15, watchOS 8, *) {
                return true
            } else {
                return false
            }
        case .preBigSur:
            if #available(macOS 11, iOS 14, watchOS 7, *) {
                return false
            } else {
                return true
            }
        case .bigSur:
            if #available(macOS 11, iOS 14, watchOS 7, *) {
                return true
            } else {
                return false
            }
        }
    }
    
    public var debugDescription: String {
        switch self {
        case .preMonterey:
            return "preMonterey"
        case .monterey:
            return "monterey"
        case .preBigSur:
            return "preBigSur"
        case .bigSur:
            return "bigSur"
        }
    }
}

/// Value representing a physical location on disk that holds a symbol
public enum CBLinkingTarget {
    /// A framework in /System/Library/Frameworks
    case framework(name: String)
    /// A framework in /System/Library/PrivateFrameworks
    case privateFramework(name: String)
    /// An arbitrary path
    case other(path: String)
    
    var path: String {
        switch self {
        case .framework(name: let name):
            return "/System/Library/Frameworks/\(name).framework/\(name)"
        case .privateFramework(name: let name):
            return "/System/Library/PrivateFrameworks/\(name).framework/\(name)"
        case .other(path: let path):
            return path
        }
    }
}

/// A symbol that can be considered during weak link reconciliation
public struct LinkingOption: CustomDebugStringConvertible {
    public static func symbol(_ symbol: String) -> LinkingOption {
        LinkingOption(constraints: [], symbol: symbol)
    }
    
    /// Constraints that must be met for this symbol to be used
    public var constraints: [CBLinkerConstraint]
    /// The symbol name as it would be passed to dlopen
    public var symbol: String
    
    /// Whether this option is safe to use in the given environment
    public var safe: Bool {
        constraints.allSatisfy(\.applies)
    }
    
    /// Constraints the symbol to preMonterey
    public var preMonterey: LinkingOption {
        LinkingOption(constraints: constraints + [.preMonterey], symbol: symbol)
    }
    
    /// Constraints the symbol to monterey or newer
    public var monterey: LinkingOption {
        LinkingOption(constraints: constraints + [.monterey], symbol: symbol)
    }
    
    /// Constrains the symbol to preBigSur
    public var preBigSur: LinkingOption {
        LinkingOption(constraints: constraints + [.preBigSur], symbol: symbol)
    }
    
    /// Constraints the symbol to big sur or newer
    public var bigSur: LinkingOption {
        LinkingOption(constraints: constraints + [.bigSur], symbol: symbol)
    }
    
    public var debugDescription: String {
        if constraints.count == 0 {
            return symbol
        } else {
            return symbol + " { " + constraints.map(\.debugDescription).joined(separator: ", ") + " }"
        }
    }
}

/// Calls the necessary stdlib function to cast a pointer to a type
private func cast<T>(_ pointer: UnsafeMutableRawPointer) -> T {
    if T.self is AnyObject.Type {
        return pointer.assumingMemoryBound(to: T.self).pointee
    } else {
        return unsafeBitCast(pointer, to: T.self)
    }
}

/// Attempts to link a symbol against a target, reconciling availability constraints and selecting the option that is safest to use
/// If no symbol is safe to use, or the target cannot be opened, nil is returned.
public func CBWeakLink<T>(against target: CBLinkingTarget, options: [LinkingOption]) -> T? {
    guard let handle = dlopen(target.path, RTLD_LAZY) else {
        log.warn("Failed to open CBLinkingTarget at path \(target.path, privacy: .public)")
        return nil
    }
    
    defer { dlclose(handle) }
    
    for option in options {
        if option.safe, let symbol = dlsym(handle, option.symbol) {
            log.debug("Selecting \(option.symbol) for linker candidate")
            
            return cast(symbol) as T
        }
    }
    
    log.warn("No viable linking option was found in target \(target.path, privacy: .public) from options \(options.map(\.debugDescription).joined(separator: ", "), privacy: .public)")
    
    return nil
}

/// Attempts to link a symbol against a target, reconciling availability constraints and selecting the option that is safest to use
/// If no symbol is safe to use, or the target cannot be opened, nil is returned.
public func CBWeakLink<T>(against target: CBLinkingTarget, _ symbol: LinkingOption) -> T? {
    CBWeakLink(against: target, options: [symbol])
}

/// Attempts to link a symbol against a target, reconciling availability constraints and selecting the option that is safest to use
/// If no symbol is safe to use, or the target cannot be opened, nil is returned.
public func CBWeakLink<T>(against target: CBLinkingTarget, _ options: LinkingOption...) -> T? {
    CBWeakLink(against: target, options: options)
}

public func CBSelectLinkingPath<Output>(_ paths: [[CBLinkerConstraint]: Output]) -> Output? {
    for option in paths.keys {
        if LinkingOption(constraints: option, symbol: "").safe {
            return paths[option]!
        }
    }
    
    return nil
}
