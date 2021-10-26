//
//  RichLinkCaptionButton.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/13/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import LinkPresentation

struct RichLinkCaptionButton: Codable, Hashable {
    init?(_ properties: LPCaptionButtonPresentationProperties) {
        guard let text = properties.text else {
            return nil
        }
        
        self.text = text
    }
    
    var text: String
}
