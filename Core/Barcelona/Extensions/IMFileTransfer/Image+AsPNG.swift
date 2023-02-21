//
//  Image+AsPNG.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 2/23/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation

#if canImport(UIKit)
import UIKit

extension Data {
    public var pngRepresentation: Data? {
        UIImage(data: self)?.pngData()
    }
}
#elseif canImport(AppKit)
import AppKit

extension Data {
    public var pngRepresentation: Data? {
        guard let cgImage = NSImage(data: self)?.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }

        return NSBitmapImageRep(cgImage: cgImage).representation(using: .png, properties: .init())
    }
}
#endif
