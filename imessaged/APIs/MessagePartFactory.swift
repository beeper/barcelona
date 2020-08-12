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

/** Takes MessageParts from API requests and converts them to an attributed string */
class MessagePartFactory {
    init(eventLoop: EventLoop) {
        self.eventLoop = eventLoop
    }
    
    let eventLoop: EventLoop
    
    var fileTransferGUIDs: [String] = []
    
    func createAttributedStringFrom(parts: [MessagePart]) -> EventLoopFuture<NSMutableAttributedString> {
        let promise = eventLoop.makePromise(of: NSMutableAttributedString.self)
        
        let futures = parts.map { self.createAttributedStringFrom(part: $0) }
        
        let futureOfStrings = EventLoopFuture<NSAttributedString>.whenAllSucceed(futures, on: eventLoop)
        
        futureOfStrings.whenSuccess { strings in
            promise.succeed(self.insertMessageParts(into: strings.reduce(into: NSMutableAttributedString()) { (accumulator, current) in
                accumulator.append(current)
            }))
        }
        
        return promise.futureResult
    }
    
    private func insertMessageParts(into string: NSMutableAttributedString) -> NSMutableAttributedString {
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
    
    private func createAttributedStringFrom(part: MessagePart) -> EventLoopFuture<NSAttributedString> {
        let promise = eventLoop.makePromise(of: NSAttributedString.self)
        
        switch part.type {
        case .text:
            DDScanServer.scanString(part.details) { res in
                let textAttributes = NSMutableAttributedString(string: part.details)
                
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
            
            break
        case .attachment:
            guard let transfer = IMFileTransferCenter.sharedInstance()?.transfer(forGUID: part.details) else {
                /** Unknown attachment */
                promise.succeed(NSAttributedString())
                break
            }
            
            fileTransferGUIDs.append(transfer.guid)
            
            let attachmentAttributes = NSMutableAttributedString(string: IMAttachmentString)
            attachmentAttributes.setAttributes([
                MessageAttributes.writingDirection: -1,
                MessageAttributes.transferGUID: transfer.guid,
                MessageAttributes.filename: transfer.filename
            ], range: NSRange(location: 0, length: IMAttachmentString.count))
            
            promise.succeed(attachmentAttributes)
            break
        }
        
        return promise.futureResult
    }
}
