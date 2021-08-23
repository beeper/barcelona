//
//  SwiftEnumCase.swift
//  BarcelonaDocs
//
//  Created by Eric Rabil on 8/17/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation

public class SwiftEnumCase: SwiftNodeLeaf, Codable {
    internal init(parent: SwiftNode, name: String, rawValue: String?, associatedValues: [String]?, attributes: [SwiftAttributes]) {
        self.parent = parent
        self.name = name
        self.rawValue = rawValue
        self.associatedValues = associatedValues
        self.attributes = attributes
    }
    
    public let parent: SwiftNode
    public let name: String
    public let rawValue: String?
    public let associatedValues: [String]?
    public let attributes: [SwiftAttributes]
}
