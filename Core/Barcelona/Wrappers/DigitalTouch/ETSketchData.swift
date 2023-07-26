//
//  ETSketchData.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/7/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import CoreGraphics
import DigitalTouchShared
import Foundation

public struct ETSketchData: Codable {
    let numberOfColors: UInt64
    let colors: [Color]
    let strokes: [[Data]]
}

// Stolen from BarcelonaFoundation
public struct Color: Codable, Hashable {
    let red: CGFloat
    let blue: CGFloat
    let green: CGFloat
    let alpha: CGFloat
}
