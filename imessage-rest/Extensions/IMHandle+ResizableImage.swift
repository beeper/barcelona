//
//  IMHandle+ResizableImage.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/5/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import Swime

struct ThumbnailImageData {
    var data: Data;
    var mime: String;
}

extension IMHandle {
    /**
     Returns true if an image exists
     */
    var hasImage: Bool {
        return person?.cnContact?.thumbnailImageData != nil
    }
    
    /**
     Generates a thumbnail image of the target size, and also returns the MIME type
     */
    func thumbnailImage(size targetingSize: Int?) -> ThumbnailImageData? {
        guard var imageData = person?.cnContact?.thumbnailImageData else { return nil }
        
        if let targetingSize = targetingSize, targetingSize > 0 {
            let image = NSImage(data: imageData)
            imageData = image?.resize(w: targetingSize, h: targetingSize) ?? imageData
        }
        
        guard let mime = Swime.mimeType(data: imageData)?.mime else { return nil }
        
        return ThumbnailImageData(data: imageData, mime: mime)
    }
}
