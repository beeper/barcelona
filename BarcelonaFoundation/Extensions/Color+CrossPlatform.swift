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

#if canImport(AppKit)
import AppKit

private func withAppearance<T>(appearance: NSAppearance, _ closure: () throws -> T) rethrows -> T {
    let previousAppearance = NSAppearance.current
    NSAppearance.current = appearance
    defer {
        NSAppearance.current = previousAppearance
    }
    
    return try closure()
}

private func withLightAppearance<T>(_ closure: () throws -> T) rethrows -> T {
    try withAppearance(appearance: NSAppearance.init(named: .aqua)!, closure)
}

private func withDarkAppearance<T>(_ closure: () throws -> T) rethrows -> T {
    try withAppearance(appearance: NSAppearance.init(named: .darkAqua)!, closure)
}
#endif

/// Cross-platform initialization of Color
public extension Color {
    init?(fromUnknown unknown: Any) {
        #if canImport(AppKit)
        self.init(fromNSColor: unknown)
        #elseif canImport(UIKit)
        self.init(fromUIColor: unknown)
        #endif
    }
    
    #if canImport(AppKit)
    init?(fromNSColor rawColor: Any) {
        guard let rawColor = rawColor as? NSColor else {
            return nil
        }
        
        if let color = rawColor.usingColorSpace(.genericRGB) {
            self.init(red: color.redComponent * 255, blue: color.blueComponent * 255, green: color.greenComponent * 255, alpha: color.alphaComponent)
        } else {
            return nil
        }
    }
    #endif
    
    #if canImport(UIKit)
    init?(fromUIColor uiColor: Any) {
        guard let uiColor = uiColor as? UIColor else {
            return nil
        }
        
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        self.init(red: red * 255, blue: blue * 255, green: green * 255, alpha: alpha)
    }
    #endif
}

public extension DynamicColor {
    init?(fromUnknown unknown: Any) {
        #if canImport(AppKit)
        self.init(fromNSColor: unknown)
        #elseif canImport(UIKit)
        self.init(fromUIColor: unknown)
        #else
        return nil
        #endif
    }
    
    init?(safeLight light: Color?, safeDark dark: Color?) {
        if light == nil && dark == nil {
            return nil
        }
        
        self.light = light
        self.dark = dark
    }
    
    #if canImport(AppKit)
    init?(fromNSColor rawColor: Any) {
        guard let rawColor = rawColor as? NSColor else {
            return nil
        }
        
        let makeColor = { () -> Color? in
            guard let color = rawColor.usingColorSpace(.genericRGB) else {
                return nil
            }
            
            return Color(fromNSColor: color)
        }
        
        self.init(safeLight: withLightAppearance(makeColor), safeDark: withDarkAppearance(makeColor))
    }
    #endif
    
    #if canImport(UIKit)
    init?(fromUIColor uiColor: Any) {
        guard let uiColor = uiColor as? UIColor else {
            return nil
        }
        
        let lightColor = Color(fromUIColor: uiColor.resolvedColor(with: .init(userInterfaceStyle: .light)))
        let darkColor = Color(fromUIColor: uiColor.resolvedColor(with: .init(userInterfaceStyle: .dark)))
        
        self.init(safeLight: lightColor, safeDark: darkColor)
    }
    #endif
}
