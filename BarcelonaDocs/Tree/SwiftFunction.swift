//
//  SwiftFunction.swift
//  BarcelonaDocs
//
//  Created by Eric Rabil on 8/17/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation

public class SwiftFunction: SwiftNodeLeaf, Codable {
    public init(attributes: [SwiftAttributes]) {
        self.attributes = attributes
    }
    
    public let attributes: [SwiftAttributes]
}
