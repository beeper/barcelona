//
//  String+FastDropURI.swift
//  Barcelona
//
//  Created by Eric Rabil on 8/3/22.
//

import Foundation

extension String {
    var fastDroppingURIPrefix: String {
        guard let index = firstIndex(of: ":") else {
            return self
        }
        guard index != endIndex else {
            return ""
        }
        return String(self[self.index(after: index)...])
    }
}

extension CustomDebugStringConvertible {
    var singleLineDebugDescription: String {
        debugDescription.replacingOccurrences(of: "\n", with: " ")
    }
}
