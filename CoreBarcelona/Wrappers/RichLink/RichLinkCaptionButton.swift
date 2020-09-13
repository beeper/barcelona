//
//  RichLinkCaptionButton.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/13/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import LinkPresentation

struct RichLinkCaptionButton: Codable {
    init(_ properties: LPCaptionButtonPresentationProperties) {
        text = properties.text
    }
    
    var text: String?
}
