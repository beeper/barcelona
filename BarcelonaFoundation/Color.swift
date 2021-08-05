//
//  Color.swift
//  BarcelonaFoundation
//
//  Created by Eric Rabil on 7/24/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import CoreGraphics

public struct Color: Codable, Hashable {
    let red: CGFloat
    let blue: CGFloat
    let green: CGFloat
    let alpha: CGFloat
}

public struct DynamicColor: Codable, Hashable {
    let light: Color?
    let dark: Color?
}
