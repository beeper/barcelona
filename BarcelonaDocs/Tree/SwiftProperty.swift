//
//  SwiftProperty.swift
//  BarcelonaDocs
//
//  Created by Eric Rabil on 8/17/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation

public class SwiftProperty: SwiftNodeLeaf, Codable {
    public init(name: String, type: ParsedType, isStatic: Bool, attributes: [SwiftAttributes]) {
        self.name = name
        self.type = type
        self.isStatic = isStatic
        self.attributes = attributes
    }
    
    public let name: String
    public let type: ParsedType
    public let isStatic: Bool
    public let attributes: [SwiftAttributes]
}
