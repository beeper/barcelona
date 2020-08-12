//
//  Constants.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/7/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation

/** Various attributes in an IMMessage attributed string. Some are no longer used by iMessage. */
struct MessageAttributes {
    static let link = NSAttributedString.Key(rawValue: "__kIMLinkAttributeName")
    static let writingDirection = NSAttributedString.Key(rawValue: "__kIMBaseWritingDirectionAttributeName")
    static let transferGUID = NSAttributedString.Key(rawValue: "__kIMFileTransferGUIDAttributeName")
    static let messagePart = NSAttributedString.Key(rawValue: "__kIMMessagePartAttributeName")
    static let filename = NSAttributedString.Key(rawValue: "__kIMFilenameAttributeName")
    static let dataDetected = NSAttributedString.Key(rawValue: "__kIMDataDetectedAttributeName")
    static let noRichLink = NSAttributedString.Key(rawValue: "__kIMNoRichLinkAttributeName")
    static let bold = NSAttributedString.Key(rawValue: "__kIMBoldAttributeName")
    static let italic = NSAttributedString.Key(rawValue: "__kIMItalicAttributeName")
    static let underline = NSAttributedString.Key(rawValue: "__kIMUnderlineAttributeName")
    static let strike = NSAttributedString.Key(rawValue: "__kIMStrikethroughAttributeName")
    static let fontSize = NSAttributedString.Key(rawValue: "__kIMFontSizeAttributeName")
}

/**
 Imma be real witchu idk why this is the attachment string but IMCore uses this
 */
let IMAttachmentString = String(data: Data(base64Encoded: "77+8")!, encoding: .utf8)!

/**
 flag <<= MessageFlags
 */
enum MessageFlags: UInt64 {
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

enum FullFlagsFromMe: UInt64 {
    case audioMessage = 19968005
    case digitalTouch = 17862661
    /**
     Plugin message
     */
    case textOrPluginOrStickerOrImage = 1085445
    case attachments = 1093637
    case richLink = 1150981
}

/**
 flag |= MessageModifier
 */
enum MessageModifiers: UInt64 {
    case expirable = 0x1000005
}
