//
//  RichLinkVideo.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/13/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import LinkPresentation

struct RichLinkVideo: Codable, Hashable, RichLinkAttachment {
    init(_ video: LPVideo, attachments: [BarcelonaAttachment]) {
        calculateAttachmentIndex(forAsset: video, attachments: attachments)
        hasAudio = video.properties?.hasAudio
        accessibilityText = video.properties?.accessibilityText
        youTubeURL = video.youTubeURL?.absoluteString
        streamingURL = video.streamingURL?.absoluteString
    }
    
    var attachmentIndex: UInt64?
    var hasAudio: Bool?
    var accessibilityText: String?
    var youTubeURL: String?
    var streamingURL: String?
}
