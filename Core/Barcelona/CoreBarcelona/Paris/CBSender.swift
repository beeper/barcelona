//
//  CBSender.swift
//  Barcelona
//
//  Created by Eric Rabil on 8/8/22.
//

import Foundation

/// Represents the sender of a message
public struct CBSender: Codable, CustomDebugStringConvertible, Equatable {
    public init(scheme: CBSender.Scheme = .other(""), value: String = "") {
        self.scheme = scheme
        self.value = value
    }

    /// Assigns a value by best-guessing the type from the URI
    init(id: String, fromMe: Bool = false) {
        if fromMe {
            scheme = .me
            return
        }
        value = id
        if id.isBusinessID {
            scheme = .biz
        } else if id.isPhoneNumber {
            scheme = .phone
        } else if id.isEmail {
            scheme = .email
        } else {
            scheme = .other("")
        }
    }

    /// Assigns a value by extracting the stored handle and initializing based on that
    init(dictionary: [AnyHashable: Any]) {
        let handle = dictionary["handle"] as? String
        self = .init(id: handle ?? "E:", fromMe: handle == nil)
    }

    public enum Scheme: Hashable {
        case biz, phone, email, me
        case other(String)
    }

    /// The type of sender for this instance
    var scheme: Scheme
    /// The address for this sender
    var value: String = ""

    public var debugDescription: String {
        "<Handle name=\(scheme.rawValue) value=\(value.isEmpty ? "true" : value)/>"
    }
}

// MARK: - Portable
extension CBSender.Scheme: RawRepresentable {
    public init(rawValue: String) {
        switch rawValue {
        case "biz": self = .biz
        case "tel": self = .phone
        case "mailto": self = .email
        case "me": self = .me
        case let other: self = .other(other)
        }
    }

    public var rawValue: String {
        switch self {
        case .biz: return "biz"
        case .phone: return "tel"
        case .email: return "mailto"
        case .me: return "me"
        case .other(let scheme): return scheme
        }
    }
}

// MARK: - Codable
extension CBSender.Scheme: Codable {
    public init(from decoder: Decoder) throws {
        let string = try String(from: decoder)
        self = .init(rawValue: string)
    }

    public func encode(to encoder: Encoder) throws {
        try rawValue.encode(to: encoder)
    }
}

// MARK: - IMCore interop

#if canImport(IMSharedUtilities)
import IMSharedUtilities

extension CBSender {
    public init(item: IMItem) {
        self = .init(id: item.sender ?? "E:", fromMe: item.isFromMe)
    }

    public init(item: IMMessageItem) {
        self = .init(id: item.handle ?? "E:", fromMe: item.isFromMe())
    }
}
#endif
