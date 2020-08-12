//
//  Image+Resize.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/5/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation

extension NSImage {
    func resize(w: Int, h: Int) -> Data? {
        let image = self
        var destSize = NSMakeSize(CGFloat(w), CGFloat(h))
        var newImage = NSImage(size: destSize)
        newImage.lockFocus()
        image.draw(in: NSMakeRect(0, 0, destSize.width, destSize.height), from: NSMakeRect(0, 0, image.size.width, image.size.height), operation: .sourceOver, fraction: CGFloat(1))
        newImage.unlockFocus()
        newImage.size = destSize
        return newImage.tiffRepresentation
    }
}
