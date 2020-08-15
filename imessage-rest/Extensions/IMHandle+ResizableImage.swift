//
//  IMHandle+ResizableImage.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/5/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

extension IMHandle {
    /**
     Returns true if an image exists
     */
    var hasImage: Bool {
        return person?.cnContact?.thumbnailImageData != nil
    }
}
