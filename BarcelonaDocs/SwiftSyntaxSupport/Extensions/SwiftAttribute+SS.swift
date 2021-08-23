//
//  SwiftAttribute+SS.swift
//  BarcelonaDocs
//
//  Created by Eric Rabil on 8/17/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import SwiftSyntax

public extension SwiftAttributes {
    static func parse(trivia piece: TriviaPiece) -> [SwiftAttributes] {
        switch piece {
        case .lineComment(let line):
            let line = line.trimmingCharacters(in: [" "])
            guard line.range(of: #"^\/\/\s\((?:([\w-]+)\s?)+\)$"#, options: .regularExpression) != nil else {
                return []
            }
            
            let rawBits = line[line.index(after: line.firstIndex(of: "(")!)...line.index(line.endIndex, offsetBy: -2)].split(separator: " ")
            
            return rawBits.compactMap {
                SwiftAttributes(rawValue: String($0))
            }
        default:
            return []
        }
    }
    
    static func parse(syntax: Syntax) -> [SwiftAttributes] {
        (syntax.leadingTrivia?.flatMap(SwiftAttributes.parse(trivia:)) ?? []) + (syntax.trailingTrivia?.flatMap(SwiftAttributes.parse(trivia:)) ?? [])
    }
}
