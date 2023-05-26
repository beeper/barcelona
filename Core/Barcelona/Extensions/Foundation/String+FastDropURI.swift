//
//  String+FastDropURI.swift
//  Barcelona
//
//  Created by Eric Rabil on 8/3/22.
//

import Foundation

public extension CustomDebugStringConvertible {
    var singleLineDebugDescription: String {
        if let dict = self as? [AnyHashable: Any] {
            return dict.imFilteredCopy().debugDescription.replacingOccurrences(of: "\n", with: " ")
        } else if let arr = self as? [[AnyHashable: Any]] {
            return arr.map({ $0.imFilteredCopy() }).debugDescription.replacingOccurrences(of: "\n", with: " ")
        }
        return debugDescription.replacingOccurrences(of: "\n", with: " ")
    }
}

extension Dictionary where Key == AnyHashable {
    func imFilteredCopy() -> Self {
        var copy = self
        copy.removeValue(forKey: "bodyData")
        copy.removeValue(forKey: "messageSummaryInfo")
        return copy
    }
}
