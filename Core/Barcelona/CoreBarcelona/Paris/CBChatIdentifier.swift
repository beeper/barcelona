//
//  CBChatIdentifier.swift
//  Barcelona
//
//  Created by Eric Rabil on 8/8/22.
//

import Foundation

/// An identifier used to group chats via many different properties
public struct CBChatIdentifier: Hashable, Equatable {
    public init(scheme: Scheme, value: String) {
        self.scheme = scheme
        self.value = value
    }

    public enum Scheme: String {
        case handleID = "handle"
        case chatIdentifier = "chat"
        case guid = "guid"
        case groupID = "gid"
        case originalGroupID = "ogid"
    }

    /// The property this identifier matches against
    public var scheme: Scheme
    /// The value to be used during matching
    public var value: String
}

// MARK: - Portable
extension CBChatIdentifier: RawRepresentable {
    public init?(rawValue: String) {
        let components = rawValue.split(separator: ":")
        guard let rawScheme = components.first.map(String.init(_:)) else {
            return nil
        }
        guard let parsedScheme = Scheme(rawValue: rawScheme) else {
            return nil
        }
        scheme = parsedScheme
        value = components.dropFirst().first.map(String.init(_:)) ?? ""
    }

    public var rawValue: String {
        "\(scheme.rawValue):\(value)"
    }
}

// MARK: - Codable
extension CBChatIdentifier: Codable {
    public func encode(to encoder: Encoder) throws {
        try scheme.rawValue.appending(":").appending(value).encode(to: encoder)
    }

    public init(from decoder: Decoder) throws {
        let str = try String(from: decoder)
        let components = str.split(separator: ":")
        guard let rawScheme = components.first.map(String.init(_:)) else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "missing scheme"))
        }
        guard let parsedScheme = Scheme(rawValue: rawScheme) else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: decoder.codingPath,
                    debugDescription: "unexpected scheme \"\(rawScheme)\"",
                    underlyingError: nil
                )
            )
        }
        scheme = parsedScheme
        value = components.dropFirst().first.map(String.init(_:)) ?? ""
    }
}

// MARK: - Convenience
extension CBChatIdentifier {
    public static func chatIdentifier(_ value: String) -> CBChatIdentifier {
        CBChatIdentifier(scheme: .chatIdentifier, value: value)
    }

    public static func guid(_ value: String) -> CBChatIdentifier {
        CBChatIdentifier(scheme: .guid, value: value)
    }

    public static func groupID(_ value: String) -> CBChatIdentifier {
        CBChatIdentifier(scheme: .groupID, value: value)
    }

    public static func originalGroupID(_ value: String) -> CBChatIdentifier {
        CBChatIdentifier(scheme: .originalGroupID, value: value)
    }
}

#if canImport(IMCore)
import IMCore
import BarcelonaDB

extension CBChatIdentifier {
    public var IMChat: IMChat? {
        switch scheme {
        case .chatIdentifier: return IMChatRegistry.shared.existingChat(withChatIdentifier: value)
        case .guid:
            return (IMChatRegistry.shared.value(forKey: "_chatGUIDToChatMap") as! NSMutableDictionary)[value] as? IMChat
        case .groupID: return IMChatRegistry.shared.existingChat(withGroupID: value)
        case .handleID: return IMChatRegistry.shared.existingChat(withChatIdentifier: value)
        default: return nil
        }
    }
}
#endif
