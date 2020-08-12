//
//  Constants.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/7/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation

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
