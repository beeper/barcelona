//
//  RichLinkCaptionText.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/13/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import BarcelonaFoundation
import LinkPresentation

struct RichLinkCaptionText: Codable, Hashable {
    init(_ properties: LPCaptionPresentationProperties) {
        text = properties.text
        
        if let color = properties.color {
            self.color = DynamicColor(fromUnknown: color)
        }
        
        maximumNumberOfLines = properties.maximumNumberOfLines?.doubleValue
        textScale = properties.textScale
    }
    
    var text: String?
    var maximumNumberOfLines: Double?
    var textScale: Double
    var color: DynamicColor?
}
