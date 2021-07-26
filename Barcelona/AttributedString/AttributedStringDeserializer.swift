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
import Combine

public struct MessagePartParseResult {
    var string: NSAttributedString
    var transferGUIDs: [String]
}

private extension NSMutableAttributedString {
    func addAttributes(_ attributes: [TextPartAttribute]? = nil) {
        guard let attributes = attributes else {
            return
        }
        
        attributes.forEach {
            self.addAttribute($0.attributedKey, value: $0.attributedValue, range: wholeRange)
        }
    }
}

/**
 Parses an array of MessageParts and returns a single NSAttributedString representing the contents
 */
public func ERAttributedString(from parts: [MessagePart]) -> Promise<MessagePartParseResult, Error> {
    Promise.whenAllSucceed(parts.map { ERAttributedString(from: $0) }).then { results in
        let strings = results.map { $0.string }
        let transferGUIDs = results.reduce(into: [String]()) { (accumulator, result) in
            accumulator.append(contentsOf: result.transferGUIDs)
        }
        
        return MessagePartParseResult(string: ERInsertMessageParts(into: strings.reduce(into: NSMutableAttributedString()) { (accumulator, current) in
            accumulator.append(current)
        }), transferGUIDs: transferGUIDs)
    }
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
private func ERAttributedString(from part: MessagePart) -> Promise<MessagePartParseResult, Error> {
    switch part.type {
    case .text:
        return ERAttributedString(forText: part.details as NSString, withAttributes: part.attributes).then { string in
            MessagePartParseResult(string: string, transferGUIDs: [])
        }
    case .breadcrumb:
        return .success(.init(string: ERAttributedString(forBreadcrumbAttributes: part.attributes ?? []), transferGUIDs: []))
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
private func ERAttributedString(forText text: NSString, withAttributes attributes: [TextPartAttribute]? = nil) -> Promise<NSAttributedString, Error> {
    Promise { resolve in
        let textAttributes = NSMutableAttributedString(string: text as String)
        textAttributes.addAttribute(MessageAttributes.writingDirection, value: -1, range: textAttributes.wholeRange)
        textAttributes.addAttributes(attributes)
        
        resolve(textAttributes)
    }
}


// MARK: - AttachmentMessagePart
private func ERAttributedString(forAttachment attachment: String) -> Promise<MessagePartParseResult, Error> {
    DBReader(pool: databasePool).attachment(for: attachment).then { representation in
        guard let representation = representation else {
            return MessagePartParseResult(string: NSAttributedString(), transferGUIDs: [])
        }
        
        let transfer = representation.fileTransfer
        
        guard let guid = transfer.guid, let filename = transfer.filename else {
            return MessagePartParseResult(string: NSAttributedString(), transferGUIDs: [])
        }
        
        let attachmentAttributes = NSMutableAttributedString(string: IMAttachmentString)
        attachmentAttributes.setAttributes([
            MessageAttributes.writingDirection: -1,
            MessageAttributes.transferGUID: guid,
            MessageAttributes.filename: filename,
        ], range: NSRange(location: 0, length: IMAttachmentString.count))
        
        return MessagePartParseResult(string: attachmentAttributes, transferGUIDs: [representation.guid])
    }
}
