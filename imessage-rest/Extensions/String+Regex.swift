//
//  String+Regex.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/5/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation

extension String {
    /**
     Return all match groups for a given regex
     */
    func groups(for regex: NSRegularExpression) -> [[String]] {
        let text = self
        let matches = regex.matches(in: text,
                                    range: NSRange(text.startIndex..., in: text))
        return matches.map { match in
            return (0..<match.numberOfRanges).map {
                let rangeBounds = match.range(at: $0)
                guard let range = Range(rangeBounds, in: text) else {
                    return ""
                }
                return String(text[range])
            }
        }
    }
    
    /**
     Returns all match groups for a given regex pattern
     */
    func groups(for regexPattern: String) -> [[String]] {
        do {
            let regex = try NSRegularExpression(pattern: regexPattern)
            return self.groups(for: regex)
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
}
