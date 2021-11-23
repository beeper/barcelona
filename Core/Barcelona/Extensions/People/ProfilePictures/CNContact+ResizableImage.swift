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

#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

public struct ThumbnailImageData {
    public var data: Data;
    public var mime: String;
}

extension Data {
    /**
     Generates a thumbnail image of the target size, and also returns the MIME type
     */
    func resized(toSize targetingSize: Int?) -> ThumbnailImageData? {
        var imageData = self
        
        if let targetingSize = targetingSize, targetingSize > 0 {
            #if canImport(UIKit)
            
            let image = UIImage(data: imageData)
            imageData = image?.resize(w: targetingSize, h: targetingSize).pngData() ?? imageData
            
            #else
            
            let image = NSImage(data: imageData)
            imageData = image?.resize(w: targetingSize, h: targetingSize) ?? imageData
            
            #endif
        }
        
        guard let mime = Swime.mimeType(data: imageData)?.mime else { return nil }
        
        return ThumbnailImageData(data: imageData, mime: mime)
    }
}
