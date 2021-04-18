//
//  RichLinkCaptionText.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/13/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import LinkPresentation

struct RichLinkCaptionText: Codable {
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
