//
//  ETSketchData.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/7/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import BarcelonaFoundation
import CoreGraphics
import DigitalTouchShared
import Foundation

public struct ETSketchData: Codable {
    let numberOfColors: UInt64
    let colors: [Color]
    let strokes: [[Data]]
}
