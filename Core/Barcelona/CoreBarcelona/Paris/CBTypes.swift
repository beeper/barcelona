//
//  CBTypes.swift
//  Barcelona
//
//  Created by Eric Rabil on 8/8/22.
//

import Foundation
import IMCore
import IMFoundation
import Logging

public enum CBChatStyle: UInt8, CaseIterable {
    case group = 43
    case instantMessage = 45

    public static func from(chatIdentifier: String) -> Self {
        // All the group chatIdentifiers I've seen have 16-18 numbers after the `chat` prefix, but I just want to be safe, so we're
        // saying that they have to have 12-20 digits (just in case we're missing something)
        chatIdentifier.range(of: "^chat\\d{12,20}$", options: .regularExpression, range: nil, locale: nil) != nil ? .group : .instantMessage
    }
}

extension IMChatStyle {
    var CBChat: CBChatStyle {
        switch self {
        case .group: return .group
        case .instantMessage: return .instantMessage
        @unknown default:
            fatalError("unknown IMChatStyle case")
        }
    }
}

public enum CBServiceName: String, Codable {
    case iMessage
    case SMS

    var service: IMServiceImpl {
        switch self {
        case .iMessage: return .iMessage()
        case .SMS: return .sms()
        }
    }
}

extension CBServiceName {
    public init(style: IMServiceStyle) {
        switch style {
        case .iMessage, .FaceTime: self = .iMessage
        case .SMS, .Phone: self = .SMS
        }
    }

    public var IMServiceStyle: IMServiceStyle {
        switch self {
        case .iMessage: return .iMessage
        case .SMS: return .SMS
        }
    }
}
