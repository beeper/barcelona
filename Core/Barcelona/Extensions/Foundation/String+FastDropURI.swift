//
//  String+FastDropURI.swift
//  Barcelona
//
//  Created by Eric Rabil on 8/3/22.
//

import Foundation

extension CustomDebugStringConvertible {
    var singleLineDebugDescription: String {
        debugDescription.replacingOccurrences(of: "\n", with: " ")
    }
}
