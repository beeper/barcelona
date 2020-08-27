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
import NIO

enum TextContentType: String, Codable {
    case link
    case calendar
    case text
}

struct TextPart: Codable {
    var type: TextContentType
    var string: String
    var data: AnyCodable?
}

private extension NSAttributedString {
    var wholeRange: NSRange {
        NSRange(location: 0, length: length)
    }
    
    var allAttributes: [NSAttributedString.Key : Any] {
        attributes(at: 0, longestEffectiveRange: nil, in: wholeRange)
    }
    
    func hasAttribute(forKey key: NSAttributedString.Key) -> Bool {
        return allAttributes[key] != nil
    }
    
    func split(_ separator: NSAttributedString.Key) -> [NSAttributedString] {
        var substrings: [NSAttributedString] = []
        
        enumerateAttribute(separator, in: wholeRange, options: .longestEffectiveRangeNotRequired) { _, range, stop in
            substrings.append(self.attributedSubstring(from: range))
        }
        
        return substrings
    }
}

func ERTextParts(from string: NSAttributedString, on eventLoop: EventLoop) -> EventLoopFuture<[TextPart]> {
    eventLoop.submit {
        var results: [TextPart] = []
        
        string.split(MessageAttributes.writingDirection).forEach { substring in
            if substring.hasAttribute(forKey: MessageAttributes.link) {
                results.append(ERTextPart(fromLink: substring))
            } else if substring.hasAttribute(forKey: MessageAttributes.calendarData) {
                results.append(ERTextPart(fromCalendar: substring))
            } else {
                results.append(ERTextPart(fromText: substring))
            }
        }
        
        return results
    }
}

// MARK: - Implementations
private func ERTextPart(fromLink attributedLink: NSAttributedString) -> TextPart {
    return TextPart(type: .link, string: attributedLink.string, data: .init(attributedLink.allAttributes[MessageAttributes.link]))
}

private func ERTextPart(fromCalendar attributedCalendar: NSAttributedString) -> TextPart {
    var unixTime: Double? = nil
    
    if let calendarData = attributedCalendar.allAttributes[MessageAttributes.calendarData] as? Data, let result = IMCopyDDScannerResultFromAttributedStringData(calendarData) as? DDScannerResult, let date = result.date(fromReferenceDate: nil, referenceTimezone: nil, timezoneRef: nil, allDayRef: nil) as? Date {
        unixTime = date.timeIntervalSince1970 * 1000
    }
    
    return TextPart(type: .calendar, string: attributedCalendar.string, data: .init(unixTime))
}

private func ERTextPart(fromText attributedText: NSAttributedString) -> TextPart {
    return TextPart(type: .text, string: attributedText.string)
}
