//
//  MessagePartFactory.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/6/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import DataDetectorsCore
import IMCore
import IMFoundation

public struct MessagePartParseResult {
    var string: NSAttributedString
    var transferGUIDs: [String]
}

private extension NSMutableAttributedString {
    func addAttributes(_ attributes: [TextPartAttribute]? = nil) {
        attributes?.forEach {
            self.addAttribute($0.attributedKey, value: $0.attributedValue, range: wholeRange)
        }
    }
}

/**
 Parses an array of MessageParts and returns a single NSAttributedString representing the contents
 */
public func ERAttributedString(from parts: [MessagePart]) -> MessagePartParseResult {
    let results = parts.map(ERAttributedString(from:))
    let strings = results.map (\.string)
    let transferGUIDs = results.flatMap(\.transferGUIDs)
    
    return MessagePartParseResult(string: ERInsertMessageParts(into: strings.reduce(into: NSMutableAttributedString()) { (accumulator, current) in
        accumulator.append(current)
    }), transferGUIDs: transferGUIDs)
}

/**
 For each part of the attributed string, insert a MessagePart index (IMCore interop)
 */
private func ERInsertMessageParts(into string: NSMutableAttributedString) -> NSMutableAttributedString {
    var thisPart = 0
    string.enumerateDelimitingAttribute(MessageAttributes.writingDirection) { range, index in
        let str = string.attributedSubstring(from: range)
        
        if str.hasAttribute(forKey: MessageAttributes.filename) && index > 0 {
            thisPart += 1
        }
        
        string.addAttribute(MessageAttributes.messagePart, value: thisPart, range: range)
        
        if str.hasAttribute(forKey: MessageAttributes.filename) && index == 0 {
            thisPart += 1
        }
    }
    
    return string
}

// MARK: - MessagePart interpreter
private func ERAttributedString(from part: MessagePart) -> MessagePartParseResult {
    switch part.type {
    case .text:
        return MessagePartParseResult(string: ERAttributedString(forText: part.details as NSString, withAttributes: part.attributes), transferGUIDs: [])
    case .breadcrumb:
        return MessagePartParseResult(string: ERAttributedString(forBreadcrumbAttributes: part.attributes ?? []), transferGUIDs: [])
    case .attachment:
        return ERAttributedString(forAttachment: part.details)
    }
}

// MARK: - BreadcrumbMessagePart
private func ERAttributedString(forBreadcrumbAttributes attributes: [TextPartAttribute]) -> NSAttributedString {
    let string = NSMutableAttributedString(string: IMBreadcrumbCharacterString)
    
    string.addAttributes(attributes)
    
    return string
}

// MARK: - TextMessagePart
private func ERAttributedString(forText text: NSString, withAttributes attributes: [TextPartAttribute]? = nil) -> NSAttributedString {
    let textAttributes = NSMutableAttributedString(string: text as String)
    textAttributes.addAttribute(MessageAttributes.writingDirection, value: -1, range: textAttributes.wholeRange)
    textAttributes.addAttributes(attributes)
    
    return textAttributes
}


// MARK: - AttachmentMessagePart
private func ERAttributedString(forAttachment attachment: String) -> MessagePartParseResult {
    guard let transfer = IMFileTransferCenter.sharedInstance().transfer(forGUID: attachment) else {
        return MessagePartParseResult(string: NSAttributedString(), transferGUIDs: [])
    }
    
    guard let guid = transfer.guid, let filename = transfer.filename else {
        return MessagePartParseResult(string: NSAttributedString(), transferGUIDs: [])
    }
    
    let attachmentAttributes = NSMutableAttributedString(string: IMAttachmentString)
    attachmentAttributes.setAttributes([
        MessageAttributes.writingDirection: -1,
        MessageAttributes.transferGUID: guid,
        MessageAttributes.filename: filename,
    ], range: NSRange(location: 0, length: IMAttachmentString.count))
    
    return MessagePartParseResult(string: attachmentAttributes, transferGUIDs: [guid])
}
