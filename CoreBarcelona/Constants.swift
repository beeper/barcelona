//
//  Constants.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/7/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import os.log
import IMCore

public let HandleQueue = DispatchQueue.init(label: "HandleIDS")

/** Various attributes in an IMMessage attributed string. Some are no longer used by iMessage. */
public struct MessageAttributes {
    static let link = NSAttributedString.Key(rawValue: IMLinkAttributeName)
    static let writingDirection = NSAttributedString.Key(rawValue: IMBaseWritingDirectionAttributeName)
    static let transferGUID = NSAttributedString.Key(rawValue: IMFileTransferGUIDAttributeName)
    static let messagePart = NSAttributedString.Key(rawValue: IMMessagePartAttributeName)
    static let filename = NSAttributedString.Key(rawValue: IMFilenameAttributeName)
    static let dataDetected = NSAttributedString.Key(rawValue: IMDataDetectedAttributeName)
    static let noRichLink = NSAttributedString.Key(rawValue: "__kIMNoRichLinkAttributeName")
    static let bold = NSAttributedString.Key(rawValue: IMBoldAttributeName)
    static let italic = NSAttributedString.Key(rawValue: IMItalicAttributeName)
    static let underline = NSAttributedString.Key(rawValue: IMUnderlineAttributeName)
    static let strike = NSAttributedString.Key(rawValue: IMStrikethroughAttributeName)
    static let fontSize = NSAttributedString.Key(rawValue: IMFontSizeAttributeName)
    static let calendarData = NSAttributedString.Key(rawValue: IMCalendarEventAttributeName)
    static let breadcrumbOptions = NSAttributedString.Key(rawValue: IMBreadcrumbTextOptionFlags)
    static let breadcrumbMarker = NSAttributedString.Key(rawValue: IMBreadcrumbTextMarkerAttributeName)
    
    @available(iOS 14, macOS 10.16, watchOS 7, *)
    static let mentionName = NSAttributedString.Key(rawValue: IMMentionConfirmedMention)
}

private func OSLog(_ category: String) -> OSLog {
    OSLog(subsystem: Bundle.main.bundleIdentifier!, category: category)
}

internal struct Logging {
    static let Registry = OSLog("Registry")
    static let Database = OSLog("Database")
}

/**
 Imma be real witchu idk why this is the attachment string but IMCore uses this
 */
public let IMAttachmentString = String(data: Data(base64Encoded: "77+8")!, encoding: .utf8)!

internal let IDSListenerID = "SOIDSListener-com.apple.imessage-rest"

/**
 flag <<= MessageFlags
 */
public enum MessageFlags: UInt64 {
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

/**
 flag |= MessageModifier
 */
public enum MessageModifiers: UInt64 {
    case expirable = 0x1000005
}

public let ERChatMessageReceivedNotification = NSNotification.Name(rawValue: "ERChatMessageReceivedNotification")
public let ERChatMessagesReceivedNotification = NSNotification.Name(rawValue: "ERChatMessagesReceivedNotification")
public let ERChatMessageSentNotification = NSNotification.Name(rawValue: "ERChatMessageSentNotification")
public let ERChatMessagesUpdatedNotification = NSNotification.Name(rawValue: "ERChatMessagesUpdatedNotification")
public let ERChatMessageUpdatedNotification = NSNotification.Name(rawValue: "ERChatMessageUpdatedNotification")
public let ERChatMessagesDeletedNotification = NSNotification.Name(rawValue: "ERChatMessagesDeletedNotification")
internal let ERChatRegistryDidLoadNotification = NSNotification.Name(rawValue: "ERChatRegistryDidLoadNotification")

public let ERDefaultMessageQueryLimit: Int64 = 75

public let ERMaximumNumberOfPinnedConversationsOverride = 100
