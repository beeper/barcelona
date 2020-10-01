//
//  RichLinkCaptionRow.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/13/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import LinkPresentation

struct RichLinkCaptionRow: Codable {
    init(_ properties: LPCaptionRowPresentationProperties) {
        if let leading = properties.leading, leading.text != nil {
            self.leading = .init(leading)
        }
        
        if let trailing = properties.trailing, trailing.text != nil {
            self.trailing = .init(trailing)
        }
        
        if let button = properties.button, button.text != nil {
            self.button = RichLinkCaptionButton(button)
        }
    }
    
    var leading: RichLinkCaptionText?
    var trailing: RichLinkCaptionText?
    var button: RichLinkCaptionButton?
}
