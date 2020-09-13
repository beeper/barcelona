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
            self.init(red: color.redComponent, blue: color.blueComponent, green: color.greenComponent, alpha: color.alphaComponent)
        } else {
            return nil
        }
        #elseif canImport(UIKit)
        if let color = unknown as? UIColor {
            self.init(red: color.red, blue: color.blue, green: color.green, alpha: color.alpha)
        } else {
            return nil
        }
        #endif
    }
}
