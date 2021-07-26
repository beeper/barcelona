//
//  MessageFlag.swift
//  Barcelona
//
//  Created by Eric Rabil on 7/24/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation

/**
 flag <<= MessageFlags
 */
public enum IMMessageFlags: UInt64 {
    case emote = 0x1
    case fromMe = 0x2
    case typingData = 0x3
    case delayed = 0x5
    case autoReply = 0x6
    case alert = 0x9
    case addressedToMe = 0xb
    case delivered = 0xc
    case read = 0xd
    case systemMessage = 0xe
    case audioMessage = 0x15
    case externalAudio = 0x2000000
    case isPlayed = 0x16
    case isLocating = 0x17
}

public enum FullFlagsFromMe: UInt64 {
    case audioMessage = 19968005
    case digitalTouch = 17862661
    /**
     Plugin message
     */
    case textOrPluginOrStickerOrImage = 1085445
    case attachments = 1093637
    case richLink = 1150981
    case incomplete = 1048581
}
