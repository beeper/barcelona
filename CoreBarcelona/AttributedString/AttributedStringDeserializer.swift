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
import NIO

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
public func ERAttributedString(from parts: [MessagePart], on eventLoop: EventLoop) -> EventLoopFuture<MessagePartParseResult> {
    let promise = eventLoop.makePromise(of: MessagePartParseResult.self)
    
    let futures = parts.map { ERAttributedString(from: $0, on: eventLoop) }
    let futureOfResults = EventLoopFuture<MessagePartParseResult>.whenAllSucceed(futures, on: eventLoop)
    
    futureOfResults.whenSuccess { results in
        let strings = results.map { $0.string }
        let transferGUIDs = results.reduce(into: [String]()) { (accumulator, result) in
            accumulator.append(contentsOf: result.transferGUIDs)
        }
        
        promise.succeed(MessagePartParseResult(string: ERInsertMessageParts(into: strings.reduce(into: NSMutableAttributedString()) { (accumulator, current) in
            accumulator.append(current)
        }), transferGUIDs: transferGUIDs))
    }
    
    return promise.futureResult
}

/**
 For each part of the attributed string, insert a MessagePart index (IMCore interop)
 */
private func ERInsertMessageParts(into string: NSMutableAttributedString) -> NSMutableAttributedString {
    var thisPart = 0
    string.enumerateDelimitingAttribute(MessageAttributes.writingDirection) { range, index in
        let str = string.attributedSubstring(from: range)
        
        string.addAttribute(MessageAttributes.messagePart, value: thisPart, range: range)
        
        if str.hasAttribute(forKey: MessageAttributes.filename) {
            thisPart += 1
        }
    }
    
    return string
}

// MARK: - MessagePart interpreter
private func ERAttributedString(from part: MessagePart, on eventLoop: EventLoop) -> EventLoopFuture<MessagePartParseResult> {
    switch part.type {
    case .text:
        return ERAttributedString(forText: part.details as NSString, withAttributes: part.attributes, on: eventLoop).map { string in
            MessagePartParseResult(string: string, transferGUIDs: [])
        }
    case .breadcrumb:
        return eventLoop.makeSucceededFuture(.init(string: ERAttributedString(forBreadcrumbAttributes: part.attributes ?? []), transferGUIDs: []))
    case .attachment:
        return ERAttributedString(forAttachment: part.details, on: eventLoop)
    }
}

// MARK: - BreadcrumbMessagePart
private func ERAttributedString(forBreadcrumbAttributes attributes: [TextPartAttribute]) -> NSAttributedString {
    let string = NSMutableAttributedString(string: IMBreadcrumbCharacterString)
    
    string.addAttributes(attributes)
    
    return string
}

// MARK: - TextMessagePart
private func ERAttributedString(forText text: NSString, withAttributes attributes: [TextPartAttribute]? = nil, on eventLoop: EventLoop) -> EventLoopFuture<NSAttributedString> {
    let promise = eventLoop.makePromise(of: NSAttributedString.self)
    
    let textAttributes = NSMutableAttributedString(string: text as String)
    
    textAttributes.addAttribute(MessageAttributes.writingDirection, value: -1, range: textAttributes.wholeRange)
    
    textAttributes.addAttributes(attributes)
    
    promise.succeed(textAttributes)
    
    return promise.futureResult
}


// MARK: - AttachmentMessagePart
private func ERAttributedString(forAttachment attachment: String, on eventLoop: EventLoop) -> EventLoopFuture<MessagePartParseResult> {
    let promise = eventLoop.makePromise(of: MessagePartParseResult.self)
    
    DBReader(pool: databasePool, eventLoop: eventLoop).attachment(for: attachment).whenComplete { result in
        switch result {
        case .success(let representation):
            guard let representation = representation else {
                promise.succeed(MessagePartParseResult(string: NSAttributedString(), transferGUIDs: []))
                return
            }
            
            let transfer = representation.fileTransfer
            
            guard let guid = transfer.guid, let filename = transfer.filename else {
                promise.succeed(MessagePartParseResult(string: NSAttributedString(), transferGUIDs: []))
                return
            }
            
            let attachmentAttributes = NSMutableAttributedString(string: IMAttachmentString)
            attachmentAttributes.setAttributes([
                MessageAttributes.writingDirection: -1,
                MessageAttributes.transferGUID: guid,
                MessageAttributes.filename: filename,
            ], range: NSRange(location: 0, length: IMAttachmentString.count))
            
            promise.succeed(MessagePartParseResult(string: attachmentAttributes, transferGUIDs: [representation.guid]))
            break
        case .failure(let error):
            promise.fail(error)
            break
        }
    }
    
    return promise.futureResult
}
