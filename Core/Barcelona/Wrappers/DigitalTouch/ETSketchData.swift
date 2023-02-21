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
    init(_ message: ETSketchMessage) {
        numberOfColors = message.numberOfColors

        colors = message.colorsInMessage.compactMap {
            Color(fromUnknown: $0)
        }

        strokes = []
    }

    let numberOfColors: UInt64
    let colors: [Color]
    let strokes: [[Data]]
}
