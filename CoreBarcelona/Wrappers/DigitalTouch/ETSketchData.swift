//
//  ETSketchData.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/7/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import DigitalTouchShared
import CoreGraphics

public struct Color: Codable {
    let red: CGFloat
    let blue: CGFloat
    let green: CGFloat
    let alpha: CGFloat
}

private func ETPExtractPoints(from strokes: [[NSValue]]) -> String? {
    let tap = ETPTap()
    
    tap.read(from: strokes)
    
    return tap.points?.base64EncodedString()
}

public struct ETSketchData: Codable {
    init(_ message: ETSketchMessage) {
        numberOfColors = message.numberOfColors
        
        colors = message.colorsInMessage.compactMap {
            Color(fromUnknown: $0)
        }
        
        strokes = []
        
        if let strokeData = ETPExtractPoints(from: message.strokes) {
            print(strokeData)
        }
    }
    
    let numberOfColors: UInt64
    let colors: [Color]
    let strokes: [[Data]]
}
