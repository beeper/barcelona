//
//  MessageAttributes.swift
//  Barcelona
//
//  Created by Eric Rabil on 7/24/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import IMFoundation
import IMSharedUtilities

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

public enum IMBaseWritingDirection: NSInteger {
    case natural = -1
    case lefttoRight = 0
    case rightToLeft = 1
}
