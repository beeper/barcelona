//
//  CBTypes.swift
//  Barcelona
//
//  Created by Eric Rabil on 8/8/22.
//

import Foundation

public enum CBChatStyle: UInt8 {
    case group = 43
    case instantMessage = 45
}

public extension CBChatStyle {
    var character: Character {
        switch self {
        case .group: return "+"
        case .instantMessage: return "-"
        }
    }
}

#if canImport(IMCore)
import IMCore

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
#endif

public enum CBServiceName: String, Codable {
    case iMessage
    case SMS
    case None
}

#if canImport(IMCore)
public extension CBServiceName {
    init(style: IMServiceStyle) {
        switch style {
        case .iMessage: self = .iMessage
        case .SMS: self = .SMS
        default: self = .None
        }
    }
    
    var IMServiceStyle: IMServiceStyle {
        switch self {
        case .iMessage: return .iMessage
        case .SMS: return .SMS
        default: return .None
        }
    }
}
#endif
