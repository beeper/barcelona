//
//  MessagePartFactory.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/6/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation

import DataDetectorsCore
import Vapor

struct MessagePartParseResult {
    var string: NSAttributedString
    var transferGUIDs: [String]
}

/**
 Parses an array of MessageParts and returns a single NSAttributedString representing the contents
 */
func ERAttributedString(from parts: [MessagePart], on eventLoop: EventLoop) -> EventLoopFuture<MessagePartParseResult> {
    let promise = eventLoop.makePromise(of: MessagePartParseResult.self)
    var fileTransferGUIDs: [String] = []
    
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
    var counter = 0
    string.enumerateAttribute(MessageAttributes.writingDirection, in: NSRange(location: 0, length: string.length), options: .init()) { _, range, _ in
        let noRichLink = string.attribute(MessageAttributes.noRichLink, existsIn: range)
        if noRichLink, counter > 0 {
            counter -= 1
        }
        
        string.addAttribute(MessageAttributes.messagePart, value: counter, range: range)
        
        if !noRichLink {
            counter += 1
        }
    }
    
    return string
}

// MARK: - MessagePart interpreter
private func ERAttributedString(from part: MessagePart, on eventLoop: EventLoop) -> EventLoopFuture<MessagePartParseResult> {
    switch part.type {
    case .text:
        return ERAttributedString(forText: part.details, on: eventLoop).map { string in
            MessagePartParseResult(string: string, transferGUIDs: [])
        }
    case .attachment:
        return ERAttributedString(forAttachment: part.details, on: eventLoop)
    }
}

// MARK: - TextMessagePart
private func ERAttributedString(forText text: String, on eventLoop: EventLoop) -> EventLoopFuture<NSAttributedString> {
    let promise = eventLoop.makePromise(of: NSAttributedString.self)
    
    DDScanServer.scanString(text) { res in
        let textAttributes = NSMutableAttributedString(string: text)
        
        var urlRanges: [NSRange] = []
        
        if let results = res as? [DDScannerResult] {
            results.forEach { result in
                switch (result.type) {
                case "WebURL":
                    let archive = try! NSKeyedArchiver.archivedData(withRootObject: result, requiringSecureCoding: false)
                    
                    let partString = textAttributes.attributedSubstring(from: result.range).string
                    guard var url = URL(string: partString) else { break }
                    if let scheme = url.scheme {
                        if !(scheme == "http" || scheme == "https") { break }
                    } else {
                        url = URL(string: "http://\(url.absoluteString)")!
                    }
                    
                    textAttributes.setAttributes([
                        MessageAttributes.dataDetected: archive,
                        MessageAttributes.writingDirection: -1,
                        MessageAttributes.link: url
                    ], range: result.range)
                    
                    urlRanges.append(result.range)
                    
                    break
                default:
                    return
                }
            }
        }
        
        var sample = textAttributes.string
        
        urlRanges.forEach { range in
            var replacement = ""
            for _ in 1...range.length {
                replacement += " "
            }
            
            print("\(replacement.count) \(range.length)")
            
            sample.replaceSubrange(Range(range, in: sample)!, with: replacement)
        }
        
        if sample.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 {
            urlRanges.forEach { range in
                textAttributes.addAttribute(MessageAttributes.noRichLink, value: 1, range: range)
            }
        }
        
        promise.succeed(textAttributes)
    }
    
    return promise.futureResult
}


// MARK: - AttachmentMessagePart
private func ERAttributedString(forAttachment attachment: String, on eventLoop: EventLoop) -> EventLoopFuture<MessagePartParseResult> {
    let promise = eventLoop.makePromise(of: MessagePartParseResult.self)
    
    DBReader(pool: db, eventLoop: eventLoop).attachment(for: attachment).whenComplete { result in
        switch result {
        case .success(let representation):
            guard let representation = representation else {
                promise.succeed(MessagePartParseResult(string: NSAttributedString(), transferGUIDs: []))
                return
            }
            
            let attachmentAttributes = NSMutableAttributedString(string: IMAttachmentString)
            attachmentAttributes.setAttributes([
                MessageAttributes.writingDirection: -1,
                MessageAttributes.transferGUID: representation.guid,
                MessageAttributes.filename: representation.path,
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
