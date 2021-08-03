//
//  RichLinkAudio.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/13/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import LinkPresentation

struct RichLinkAudio: Codable, Hashable, RichLinkAttachment {
    init(_ audio: LPAudio, attachments: [BarcelonaAttachment]) {
        calculateAttachmentIndex(forAsset: audio, attachments: attachments)
        accessibilityText = audio.properties?.accessibilityText
        streamingURL = audio.streamingURL?.absoluteString
    }
    
    var attachmentIndex: UInt64?
    var accessibilityText: String?
    var streamingURL: String?
}
