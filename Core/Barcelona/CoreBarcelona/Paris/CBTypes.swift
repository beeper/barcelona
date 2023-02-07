//
//  CBTypes.swift
//  Barcelona
//
//  Created by Eric Rabil on 8/8/22.
//

import Foundation
import IMFoundation
import IMCore

public enum CBChatStyle: UInt8, CaseIterable {
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

public extension CBServiceName {
    init(style: IMServiceStyle) {
        switch style {
        case .iMessage, .FaceTime: self = .iMessage
        case .SMS, .Phone: self = .SMS
        }
    }
    
    var IMServiceStyle: IMServiceStyle {
        switch self {
        case .iMessage: return .iMessage
        case .SMS: return .SMS
        }
    }
}

