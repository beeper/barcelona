//
//  RichLink.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/12/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import LinkPresentation

private extension LPLinkMetadata {
    private var _presentationProperties: LPWebLinkPresentationProperties? {
        guard let linkView = LPLinkView(metadata: self) else {
            return nil
        }
        
        let LPLinkMetadataPresentationTransformer = NSClassFromString("LPLinkMetadataPresentationTransformer") as! NSObject.Type
        
        let transformer = LPLinkMetadataPresentationTransformer.init()
        
        transformer.setValue(self, forKey: "metadata")
        transformer.setValue(linkView.value(forKey: "URL"), forKey: "URL")
        transformer.setValue(linkView.value(forKey: "_metadataIsComplete"), forKey: "complete")
        transformer.setValue(linkView._allowsTapToLoad, forKey: "allowsTapToLoad")
        transformer.setValue(linkView._preferredSizeClass, forKey: "preferredSizeClass")
        transformer.setValue(linkView._sourceBundleIdentifier, forKey: "sourceBundleIdentifier")
        
        guard let unmanagedProperties = transformer.perform(Selector(("presentationProperties"))), let properties = unmanagedProperties.takeUnretainedValue() as? LPWebLinkPresentationProperties else {
            return nil
        }
        
        return properties
    }
    
    var presentationProperties: LPWebLinkPresentationProperties? {
        if Thread.isMainThread {
            return _presentationProperties
        }
        
        var properties: LPWebLinkPresentationProperties? = nil
        
        DispatchQueue.main.sync {
            properties = _presentationProperties
        }
        
        return properties
    }
}

extension NSObject {
    static func emptyObject() -> Self {
        perform(Selector("alloc"))!.takeUnretainedValue().perform(Selector("init")).takeUnretainedValue() as! Self
    }
}

/// Codable representation of a rich link
public struct RichLinkRepresentation: Codable {
    init?(metadata: LPLinkMetadata, attachments: [InternalAttachment]) {
        guard let properties = metadata.presentationProperties else {
            return nil
        }
        
        if let captionBar = properties.captionBar, captionBar.hasAnyContent {
            self.captionBar = .init(captionBar, attachments: attachments)
        }
        
        if let mediaTopCaptionBar = properties.mediaTopCaptionBar, mediaTopCaptionBar.hasAnyContent {
            self.mediaTopCaptionBar = .init(mediaTopCaptionBar, attachments: attachments)
        }
        
        if let mediaBottomCaptionBar = properties.mediaBottomCaptionBar, mediaBottomCaptionBar.hasAnyContent {
            self.mediaBottomCaptionBar = .init(mediaBottomCaptionBar, attachments: attachments)
        }
        
        if let color = properties.backgroundColor {
            self.backgroundColor = Color(fromUnknown: color)
        }
        
        if let image = properties.image {
            self.image = RichLinkImage(image, properties.imageProperties, attachments: attachments)
        }
        
        if let video = properties.video {
            self.video = RichLinkVideo(video, attachments: attachments)
        }
        
        if let audio = properties.audio {
            self.audio = RichLinkAudio(audio, attachments: attachments)
        }
        
        self.style = RichLinkStyle(rawValue: Int(properties.style))?.id
        self.itemType = metadata.itemType
        self.quotedText = properties.quotedText
        self.preliminary = properties.isPreliminary
        self.url = metadata.originalURL
        self.specialization = metadata.specialization?.format
    }
    
    var captionBar: RichLinkCaption?
    var mediaTopCaptionBar: RichLinkCaption?
    var mediaBottomCaptionBar: RichLinkCaption?
    var image: RichLinkImage?
    var video: RichLinkVideo?
    var audio: RichLinkAudio?
    var url: URL?
    var link: URL?
    var backgroundColor: Color?
    var style: String?
    var itemType: String?
    var quotedText: String?
    var specialization: RichLinkSpecializationFormat?
    var preliminary: Bool?
}
