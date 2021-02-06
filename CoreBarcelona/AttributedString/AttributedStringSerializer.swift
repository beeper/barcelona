//
//  AttributedStringSerializer.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 8/26/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import AnyCodable
import DataDetectorsCore
import IMCore
import NIO

internal extension NSAttributedString {
    var wholeRange: NSRange {
        NSRange(location: 0, length: length)
    }
    
    fileprivate var allAttributes: [NSAttributedString.Key : Any] {
        var attributes: [NSAttributedString.Key: Any] = [:]
        
        enumerateDelimitingAttribute(MessageAttributes.writingDirection) { range, counter in
            enumerateAttributes(in: range, options: .longestEffectiveRangeNotRequired) { subAttributes, range, _ in
                subAttributes.forEach {
                    attributes[$0.key] = $0.value
                }
            }
        }
        
        return attributes
    }
    
    func hasAttribute(forKey key: NSAttributedString.Key) -> Bool {
        return allAttributes[key] != nil
    }
    
    func enumerateDelimitingAttribute(_ attribute: NSAttributedString.Key, using cb: (NSRange, inout Int) -> ()) {
        var counter = 0
        enumerateAttribute(attribute, in: wholeRange, options: .longestEffectiveRangeNotRequired) { _, range, _ in
            cb(range, &counter)
            counter += 1
        }
    }
    
    func split(_ separator: NSAttributedString.Key) -> [NSAttributedString] {
        var substrings: [NSAttributedString] = []
        
        enumerateAttribute(separator, in: wholeRange, options: .longestEffectiveRangeNotRequired) { _, range, stop in
            substrings.append(self.attributedSubstring(from: range))
        }
        
        return substrings
    }
}

public func ERTextParts(from string: NSAttributedString) -> [TextPart] {
    var results: [TextPart] = []
    
    let textTracking = ERTrack(log: .default, name: "ERTextParts Computation", format: "")
    
    string.split(MessageAttributes.writingDirection).forEach { substring in
        var textPart: TextPart!
        
        if substring.hasAttribute(forKey: MessageAttributes.link) {
            let textLink = ERTrack(log: .default, name: "ERTextParts .link", format: "")
            textPart = ERTextPart(fromLink: substring)
            textLink()
        } else if substring.hasAttribute(forKey: MessageAttributes.calendarData) {
            let calMatch = ERTrack(log: .default, name: "ERTextParts .calendarData", format: "")
            textPart = ERTextPart(fromCalendar: substring)
            calMatch()
        } else if substring.hasAttribute(forKey: MessageAttributes.breadcrumbOptions) {
            textPart = ERTextPart(fromBreadcrumb: substring)
        } else if #available(iOS 14, macOS 10.16, watchOS 7, *), substring.hasAttribute(forKey: MessageAttributes.mentionName) {
            textPart = ERTextPart(fromMention: substring)
        } else {
            let textMatch = ERTrack(log: .default, name: "ERTextParts .text", format: "")
            textPart = ERTextPart(fromText: substring)
            textMatch()
        }
        
        ERInsertAttributesForTextPart(&textPart, string: substring)
        
        results.append(textPart)
    }
    
    textTracking()
    
    return results
}

private func ERInsertAttributesForTextPart(_ textPart: inout TextPart, string: NSAttributedString) {
    string.allAttributes.forEach {
        if let attribute = TextPartAttribute(attributedKey: $0.key, rawValue: $0.value) {
            if textPart.attributes == nil {
                textPart.attributes = []
            }
            
            textPart.attributes?.append(attribute)
        }
    }
}

// MARK: - Implementations
private func ERTextPart(fromLink attributedLink: NSAttributedString) -> TextPart {
    return TextPart(type: .link, string: attributedLink.string, data: .init(attributedLink.allAttributes[MessageAttributes.link]))
}

private func ERTextPart(fromMention mentionText: NSAttributedString) -> TextPart {
    return TextPart(type: .text, string: mentionText.string)
}

private func ERTextPart(fromBreadcrumb breadcrumb: NSAttributedString) -> TextPart {
    return TextPart(type: .breadcrumb, string: breadcrumb.string)
}

private func ERTextPart(fromCalendar attributedCalendar: NSAttributedString) -> TextPart {
    var unixTime: Double? = nil
    
    if let calendarData = attributedCalendar.allAttributes[MessageAttributes.calendarData] as? Data {
        var result = IMCopyDDScannerResultFromAttributedStringData(calendarData)
        
        if let date = result?.date(fromReferenceDate: nil, referenceTimezone: nil, timezoneRef: nil, allDayRef: nil) as? Date {
            unixTime = date.timeIntervalSince1970 * 1000
        }
        
        CFRelease(result!)
        result = nil
    }
    
    return TextPart(type: .calendar, string: attributedCalendar.string, data: .init(unixTime))
}

private func ERTextPart(fromText attributedText: NSAttributedString) -> TextPart {
    return TextPart(type: .text, string: attributedText.string)
}
