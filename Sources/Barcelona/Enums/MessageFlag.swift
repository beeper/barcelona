//
//  MessageFlag.swift
//  Barcelona
//
//  Created by Eric Rabil on 7/24/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation

public struct IMMessageFlags: OptionSet, ExpressibleByIntegerLiteral, Codable, Hashable {
    public init(integerLiteral value: UInt64) {
        self.rawValue = value
    }
    
    public typealias IntegerLiteralType = UInt64
    
    public let rawValue: UInt64
    
    public init(rawValue: UInt64) {
        self.rawValue = rawValue
    }
    
    public static let finished:        IMMessageFlags = 0x1
    public static let emote:           IMMessageFlags = 0x2
    public static let fromMe:          IMMessageFlags = 0x4
    public static let empty:           IMMessageFlags = 0x8
    public static let delayed:         IMMessageFlags = 0x20
    public static let autoReply:       IMMessageFlags = 0x40
    public static let alert:           IMMessageFlags = 0x200
    public static let prepared:        IMMessageFlags = 0x800
    public static let delivered:       IMMessageFlags = 0x1000
    public static let read:            IMMessageFlags = 0x2000
    public static let systemMessage:   IMMessageFlags = 0x4000
    public static let sent:            IMMessageFlags = 0x8000
    public static let hasDDResults:    IMMessageFlags = 0x10000
    
    public static let serviceMessage:  IMMessageFlags = 0x20000
    public static let forward:         IMMessageFlags = 0x40000
    public static let downgraded:      IMMessageFlags = 0x80000
    public static let dataDetected:    IMMessageFlags = 0x100000
    public static let audioMessage:    IMMessageFlags = 0x200000
    public static let played:          IMMessageFlags = 0x400000
    public static let locating:        IMMessageFlags = 0x800000
    public static let expirable:       IMMessageFlags = 0x1000000
    public static let fromExtSource:   IMMessageFlags = 0x2000000
    
    public static let corrupt:         IMMessageFlags = 0x4000000
    public static let spam:            IMMessageFlags = 0x8000000
    
    public static let legacyBits:      IMMessageFlags = 0xee000000
}

public enum IMMessageDescriptionType: Int64 {
    case accessibility
    case acknowledgment
    case conversationList
    case notification
    case siri
    case spi
}
