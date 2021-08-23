//
//  SwiftNode.swift
//  BarcelonaDocs
//
//  Created by Eric Rabil on 8/17/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import SwiftSyntax

public class SwiftNode: Codable {
    public init(name: String, nodes: [SwiftNode] = [], properties: [SwiftProperty] = [], functions: [SwiftFunction] = [], cases: [SwiftEnumCase] = [], type: SwiftNode.SwiftNodeType? = nil) {
        self.name = name
        self.nodes = nodes
        self.properties = properties
        self.functions = functions
        self.cases = cases
        self.type = type
    }
    
    public var nodes: [SwiftNode] = []
    public var properties: [SwiftProperty] = []
    public var functions: [SwiftFunction] = []
    public var cases: [SwiftEnumCase] = []
    public var attributes: [SwiftAttributes] = []
    public var type: SwiftNodeType!
    public var name: String
    
    public enum SwiftNodeType: String, Codable {
        case `enum`
        case `class`
        case `struct`
        case `protocol`
    }
}

