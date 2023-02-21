//
//  CBTranscoding.swift
//  Barcelona
//
//  Created by Eric Rabil on 6/8/22.
//

import CoreImage
import Foundation

public struct CBTranscoding {
}

extension CBTranscoding {
    public static func toJPEG(contentsOf url: URL) -> Data? {
        let context = CIContext(options: nil)
        let options = [
            CIImageRepresentationOption.init(rawValue: kCGImageDestinationLossyCompressionQuality as String): 1.0
        ]
        guard let image = CIImage(contentsOf: url) else {
            return nil
        }
        return context.jpegRepresentation(of: image, colorSpace: image.colorSpace!, options: options)
    }
}
