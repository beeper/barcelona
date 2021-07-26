//
//  RichLinkAttachment+LPAssetResolution.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/13/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import LinkPresentation

private extension NSObject {
    var theClassName: String {
        return NSStringFromClass(type(of: self))
    }
}

extension RichLinkAttachment {
    /// Supports the RichLinkProvider substitution API
    mutating func calculateAttachmentIndex(forAsset asset: LPAsset, attachments: [InternalAttachment]) {
        switch asset.theClassName {
        case "RichLinkAudioAttachmentSubstitute":
            fallthrough
        case "RichLinkVideoAttachmentSubstitute":
            fallthrough
        case "LPImageAttachmentSubstitute":
            fallthrough
        case "LPVideoAttachmentSubstitute":
            fallthrough
        case "LPAudioAttachmentSubstitute":
            fallthrough
        case "RichLinkImageAttachmentSubstitute":
            if let substituteIndex = asset.value(forKey: "index") as? UInt64 {
                self.attachmentIndex = substituteIndex
            }
            break
        default:
            if let url = asset.fileURL, let index = attachments.firstIndex(where: {
                $0.path == url.absoluteString
            }) {
                self.attachmentIndex = UInt64(index)
            }
        }
    }
}
