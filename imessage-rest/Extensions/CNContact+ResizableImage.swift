//
//  CNContact+ResizableImage.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/8/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Swime
import Foundation
import Contacts

extension CNContact {
    /**
     Generates a thumbnail image of the target size, and also returns the MIME type
     */
    func thumbnailImage(size targetingSize: Int?) -> ThumbnailImageData? {
        guard var imageData = thumbnailImageData else { return nil }
        
        if let targetingSize = targetingSize, targetingSize > 0 {
            let image = NSImage(data: imageData)
            imageData = image?.resize(w: targetingSize, h: targetingSize) ?? imageData
        }
        
        guard let mime = Swime.mimeType(data: imageData)?.mime else { return nil }
        
        return ThumbnailImageData(data: imageData, mime: mime)
    }
}
