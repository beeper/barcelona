//
//  SwiftNodeLeaf.swift
//  BarcelonaDocs
//
//  Created by Eric Rabil on 8/17/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation

public enum SwiftAttributes: String, Codable {
    case exposed = "bl-api-exposed"
    case omit = "bl-api-omit"
}

public protocol SwiftNodeLeaf: Codable {
    var attributes: [SwiftAttributes] { get }
}
