//
//  RichLinkMetadata.swift
//  Barcelona
//
//  Created by Eric Rabil on 2/15/22.
//

import Foundation
import LinkPresentation

/// Wire-serializable struct for rich links
public struct RichLinkMetadata: Codable, Hashable {
    public typealias RichLinkImage = RichLinkAsset.Source
    
    public struct RichLinkAsset: Codable, Hashable {
        public enum Source: Codable, Hashable {
            /// Where is the asset downloaded to
            case url(URL)
            /// Inline asset data
            case data(Data)
            
            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                if container.allKeys.contains(.data) {
                    self = .data(try container.decode(Data.self, forKey: .data))
                } else if container.allKeys.contains(.url) {
                    let urlString = try container.decode(String.self, forKey: .url)
                    guard let url = Foundation.URL(string: urlString) else {
                        throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "attempt to decode malformed URL"))
                    }
                    self = .url(url)
                } else {
                    throw DecodingError.dataCorrupted(.init(codingPath: container.codingPath, debugDescription: "no valid matches"))
                }
            }
            
            public func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                switch self {
                case .url(let url): try container.encode(url.absoluteString, forKey: .url)
                case .data(let data): try container.encode(data.base64EncodedString(), forKey: .data)
                }
            }
            
            private enum CodingKeys: String, CodingKey {
                case url, data
            }
        }
        
        public struct Size: Codable, Hashable {
            public var width: Double
            public var height: Double
            
            public init(cg: CGSize) {
                width = Double(cg.width)
                height = Double(cg.height)
            }
            
            public init(width: Double, height: Double) {
                self.width = width
                self.height = height
            }
            
            var cg: CGSize {
                CGSize(width: CGFloat(width), height: CGFloat(height))
            }
        }
        
        public var mimeType: String?
        public var accessibilityText: String?
        public var source: Source?
        /// Where was the asset downloaded from
        public var originalURL: URL?
        public var size: Size?
    }
    
    public struct RichLinkVideoAsset: Codable, Hashable {
        public var hasAudio: Bool?
        public var youTubeURL: URL?
        public var streamingURL: URL?
        public var asset: RichLinkAsset
    }
    
    /// Converts an LPLinkMetadata object to wire format to be sent to arbitrary consumers
    public init(metadata: LPLinkMetadata) {
        originalURL = metadata.originalURL
        URL = metadata.url
        title = metadata.title
        summary = metadata.summary
        selectedText = metadata.selectedText
        siteName = metadata.siteName
        relatedURL = metadata.relatedURL
        creator = metadata.creator
        creatorFacebookProfile = metadata.creatorFacebookProfile
        creatorTwitterUsername = metadata.creatorTwitterUsername
        itemType = metadata.itemType
        icon = .init(solid: metadata.icon, metadata: metadata.iconMetadata)
        image = .init(solid: metadata.image, metadata: metadata.imageMetadata)
        video = .init(solid: metadata.video, metadata: metadata.videoMetadata)
        audio = .init(solid: metadata.audio, metadata: metadata.audioMetadata)
        images = metadata.images?.compactMap { .init(solid: nil, metadata: $0) }
        videos = metadata.videos?.compactMap { .init(solid: nil, metadata: $0) }
        streamingVideos = metadata.streamingVideos?.compactMap { .init(solid: nil, metadata: $0) }
        audios = metadata.audios?.compactMap { .init(solid: nil, metadata: $0) }
        if images?.isEmpty != false {
            images = nil
        }
        if videos?.isEmpty != false {
            videos = nil
        }
        if streamingVideos?.isEmpty != false {
            streamingVideos = nil
        }
        if audios?.isEmpty != false {
            audios = nil
        }
    }
    
    public init() {
        
    }
    
    public var originalURL: URL?
    public var URL: URL?
    public var title: String?
    public var summary: String?
    public var selectedText: String?
    public var siteName: String?
    public var relatedURL: URL?
    public var creator: String?
    public var creatorFacebookProfile: String?
    public var creatorTwitterUsername: String?
    public var itemType: String?
    public var icon: RichLinkAsset?
    public var image: RichLinkAsset?
    public var video: RichLinkVideoAsset?
    public var audio: RichLinkAsset?
    public var images: [RichLinkAsset]?
    public var videos: [RichLinkAsset]?
    public var streamingVideos: [RichLinkAsset]?
    public var audios: [RichLinkAsset]?
    
    /// Rebuilds an LPLinkMetadata object from wire format to be sent over iMessage
    public func createLinkMetadata() -> LPLinkMetadata {
        let metadata = LPLinkMetadata()!
        metadata.originalURL = originalURL
        metadata.url = URL
        metadata.title = title
        metadata.summary = summary
        metadata.selectedText = selectedText
        metadata.siteName = siteName
        metadata.relatedURL = relatedURL
        metadata.creator = creator
        metadata.creatorFacebookProfile = creatorFacebookProfile
        metadata.creatorTwitterUsername = creatorTwitterUsername
        metadata.itemType = itemType
        metadata.icon = icon?.lpImage
        metadata.iconMetadata = icon?.lpIconMetadata
        metadata.image = image?.lpImage
        metadata.imageMetadata = image?.lpImageMetadata
        metadata.video = video?.lpVideo
        metadata.videoMetadata = video?.asset.lpVideoMetadata
        metadata.audio = audio?.lpAudio
        metadata.audioMetadata = audio?.lpAudioMetadata
        metadata.images = images?.compactMap(\.lpImageMetadata)
        metadata.videos = videos?.compactMap(\.lpVideoMetadata)
        metadata.audios = audios?.map(\.lpAudioMetadata)
        metadata.streamingVideos = streamingVideos?.compactMap(\.lpVideoMetadata)
        return metadata
    }
}

// MARK: - LinkPresentation -> Wire

// Mush

private protocol LPSolidAssetConforming: NSObjectProtocol {
    var mimeType: String! { get }
    var data: Data! { get }
    var fileURL: URL! { get set }
}

private protocol LPSolidAssetMetadataConforming: NSObjectProtocol {
    var accessibilityText: String! { get set }
    var url: URL! { get set }
    var size: CGSize { get set }
}

extension LPVideo: LPSolidAssetConforming {}
extension LPImage: LPSolidAssetConforming {}
extension LPAudio: LPSolidAssetConforming {}

extension LPVideoMetadata: LPSolidAssetMetadataConforming {}
extension LPImageMetadata: LPSolidAssetMetadataConforming {}
extension LPIconMetadata: LPSolidAssetMetadataConforming {
    fileprivate var size: CGSize {
        get { .zero }
        set {}
    }
}
extension LPAudioMetadata: LPSolidAssetMetadataConforming {
    fileprivate var size: CGSize {
        get { .zero }
        set {}
    }
}

private extension LPSolidAssetMetadataConforming {
    var canHaveASize: Bool {
        switch self {
        case is LPIconMetadata, is LPAudioMetadata:
            return false
        default:
            return true
        }
    }
}

/// From LP
private extension RichLinkMetadata.RichLinkAsset {
    init?(solid: LPSolidAssetConforming?, metadata: LPSolidAssetMetadataConforming?) {
        if solid == nil, metadata == nil {
            return nil
        }
        mimeType = solid?.mimeType
        accessibilityText = metadata?.accessibilityText
        if let data = solid?.data {
            source = .data(data)
        } else if let url = solid?.fileURL {
            source = .url(url)
        }
        originalURL = metadata?.url
        if let cgSize = metadata?.size, metadata?.canHaveASize == true {
            size = .init(cg: cgSize)
        }
    }
}

// MARK: - LPImage, LPAudio, LPVideo, LPImageMetadata, LPAudioMetadata, LPVideoMetadata, LPIconMetadata

fileprivate extension RichLinkMetadata.RichLinkVideoAsset {
    init?(solid: LPVideo?, metadata: LPVideoMetadata?) {
        guard let asset = RichLinkMetadata.RichLinkAsset(solid: solid, metadata: metadata) else {
            return nil
        }
        hasAudio = solid?.hasAudio
        youTubeURL = solid?.youTubeURL
        streamingURL = solid?.streamingURL
        self.asset = asset
    }
    
    private var lpVideoProperties: LPVideoProperties {
        let properties = LPVideoProperties()
        properties.accessibilityText = asset.accessibilityText
        properties.hasAudio = hasAudio ?? true
        return properties
    }
    
    var lpVideo: LPVideo? {
        if let youTubeURL = youTubeURL {
            return LPVideo(youTubeURL: youTubeURL, properties: lpVideoProperties)
        }
        if let streamingURL = streamingURL {
            return LPVideo(streamingURL: streamingURL, properties: lpVideoProperties)
        }
        switch asset.source {
        case .url(let url):
            return LPVideo(byReferencingFileURL: url, mimeType: asset.mimeType, properties: lpVideoProperties)
        case .data(let data):
            return LPVideo(data: data, mimeType: asset.mimeType, properties: lpVideoProperties)
        default:
            return nil
        }
    }
}

fileprivate extension RichLinkMetadata.RichLinkAsset {
    var lpImageProperties: LPImageProperties? {
        guard let accessibilityText = accessibilityText else {
            return nil
        }
        let properties = LPImageProperties()
        properties.accessibilityText = accessibilityText
        return properties
    }
    
    var lpImage: LPImage? {
        switch source {
        case .url(let url):
            if let lpImageProperties = lpImageProperties {
                return LPImage(byReferencingFileURL: url, mimeType: mimeType, properties: lpImageProperties)
            } else {
                return LPImage(byReferencingFileURL: url, mimeType: mimeType)
            }
        case .data(let data):
            if let lpImageProperties = lpImageProperties {
                return LPImage(data: data, mimeType: mimeType, properties: lpImageProperties)
            } else {
                return LPImage(data: data, mimeType: mimeType)
            }
        default:
            return nil
        }
    }
    
    var lpAudioProperties: LPAudioProperties? {
        guard let accessibilityText = accessibilityText else {
            return nil
        }
        let properties = LPAudioProperties()
        properties.accessibilityText = accessibilityText
        return properties
    }
    
    var lpAudio: LPAudio? {
        switch source {
        case .url(let url):
            return LPAudio(byReferencingFileURL: url, mimeType: mimeType, properties: lpAudioProperties)
        default:
            return nil
        }
    }
    
    var lpVideoMetadata: LPVideoMetadata? {
        guard let size = size else {
            return nil
        }
        let metadata = LPVideoMetadata()!
        metadata.size = size.cg
        metadata.url = originalURL
        metadata.accessibilityText = accessibilityText
        return metadata
    }
    
    var lpAudioMetadata: LPAudioMetadata {
        let metadata = LPAudioMetadata()!
        metadata.url = originalURL
        metadata.accessibilityText = accessibilityText
        return metadata
    }
    
    var lpImageMetadata: LPImageMetadata? {
        guard let size = size else {
            return nil
        }
        let metadata = LPImageMetadata()!
        metadata.url = originalURL
        metadata.size = size.cg
        metadata.accessibilityText = accessibilityText
        return metadata
    }
    
    var lpIconMetadata: LPIconMetadata {
        let metadata = LPIconMetadata()!
        metadata.url = originalURL
        metadata.accessibilityText = accessibilityText
        return metadata
    }
}
