//
//  RichLinkExternalComposition.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 10/8/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import LinkPresentation

public struct RichLinkExternalAssetComposition: Codable {
    var iconID: String?
    var imageID: String?
    var videoID: String?
    var youTubeVideo: Bool?
    var audioID: String?
    
    public var icon: LPImage? {
        nil
    }
    
    public var image: LPImage? {
        nil
    }
    
    public var video: LPVideo? {
        nil
    }
    
    public var isYouTubeVideo: Bool {
        (youTubeVideo ?? false) == true
    }
    
    public var audio: LPAudio? {
        nil
    }
}

public struct RichLinkExternalComposition: Codable {
    var originalURL: String?
    var url: String?
    var title: String?
    var summary: String?
    var selectedText: String?
    var siteName: String?
    var itemType: String?
    var relatedURL: String?
    var creator: String?
    var creatorFacebookProfile: String?
    var creatorTwitterUsername: String?
    var appleContentID: String?
    var appleSummary: String?
}
