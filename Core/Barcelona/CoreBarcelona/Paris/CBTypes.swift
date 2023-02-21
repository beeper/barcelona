//
//  CBTypes.swift
//  Barcelona
//
//  Created by Eric Rabil on 8/8/22.
//

import Foundation
import IMCore
import IMFoundation

public enum CBChatStyle: UInt8, CaseIterable {
    case group = 43
    case instantMessage = 45
}

extension CBChatStyle {
    public var character: Character {
        switch self {
        case .group: return "+"
        case .instantMessage: return "-"
        }
    }
}

extension CBChatStyle {
    var IMCore: IMChatStyle {
        switch self {
        case .group: return .group
        case .instantMessage: return .instantMessage
        }
    }
}

extension IMChatStyle {
    var CBChat: CBChatStyle {
        switch self {
        case .group: return .group
        case .instantMessage: return .instantMessage
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
