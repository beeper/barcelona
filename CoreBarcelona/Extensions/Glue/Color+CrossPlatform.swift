//
//  Color+CrossPlatform.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/13/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

/// Cross-platform initialization of Color
internal extension Color {
    init?(fromUnknown unknown: Any) {
        #if canImport(AppKit)
        if let rawColor = unknown as? NSColor, let color = rawColor.usingColorSpace(.genericRGB) {
            self.init(red: color.redComponent * 255, blue: color.blueComponent * 255, green: color.greenComponent * 255, alpha: color.alphaComponent)
        } else {
            return nil
        }
        #elseif canImport(UIKit)
        if let color = unknown as? UIColor {
            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
            color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            self.init(red: red * 255, blue: blue * 255, green: green * 255, alpha: alpha)
        } else {
            return nil
        }
        #endif
    }
}
