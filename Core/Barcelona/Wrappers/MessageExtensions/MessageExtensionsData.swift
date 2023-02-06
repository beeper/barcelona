//
//  MessageExtensionsData.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/15/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import IMSharedUtilities
import AnyCodable
import Gzip
import Swime
import Logging
import UniformTypeIdentifiers

private let UnarchivingClasses = [
    NSMutableString.self,
    NSString.self,
    NSMutableDictionary.self,
    NSDictionary.self,
    NSUUID.self,
    NSData.self,
    NSURL.self,
    NSMutableData.self,
    NSValue.self,
    NSNumber.self
]

private let IMBusinessTapActionKey = "tap-action"

extension String {
    var numberValue: NSNumber? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.number(from: self)
    }
    
    var boolValue: Bool? {
        switch self.lowercased() {
        case "true":
            return true
        case "false":
            return false
        default:
            return nil
        }
    }
    
    var expandingTildeInPath: String {
        (self as NSString).expandingTildeInPath
    }
}

public struct MessageExtensionsLayoutInfo: Codable, Hashable {
    public init?(_ dictionary: NSDictionary? = nil) {
        guard let dictionary = dictionary else {
            return nil
        }
        
        imageSubtitle = dictionary[IMBalloonLayoutInfoImageSubTitleKey] as? String
        imageTitle = dictionary[IMBalloonLayoutInfoImageTitleKey] as? String
        caption = dictionary[IMBalloonLayoutInfoCaptionKey] as? String
        subcaption = dictionary[IMBalloonLayoutInfoSubcaptionKey] as? String
        secondarySubcaption = dictionary[IMBalloonLayoutInfoSecondarySubcaptionKey] as? String
        tertiarySubcaption = dictionary[IMBalloonLayoutInfoTertiarySubcaptionKey] as? String
        tapAction = dictionary[IMBusinessTapActionKey] as? Int
    }
    
    public var dictionary: NSDictionary {
        let dictionary = NSMutableDictionary()
        
        dictionary[IMBalloonLayoutInfoImageSubTitleKey] = imageSubtitle as NSString?
        dictionary[IMBalloonLayoutInfoImageTitleKey] = imageTitle as NSString?
        dictionary[IMBalloonLayoutInfoCaptionKey] = caption as NSString?
        dictionary[IMBalloonLayoutInfoSubcaptionKey] = subcaption as NSString?
        dictionary[IMBalloonLayoutInfoSecondarySubcaptionKey] = secondarySubcaption as NSString?
        dictionary[IMBalloonLayoutInfoTertiarySubcaptionKey] = tertiarySubcaption as NSString?
        dictionary[IMBusinessTapActionKey] = tapAction as NSNumber?
        
        return dictionary
    }
    
    public var imageSubtitle: String?
    public var imageTitle: String?
    public var caption: String?
    public var subcaption: String?
    public var secondarySubcaption: String?
    public var tertiarySubcaption: String?
    public var tapAction: Int?
}

private extension String {
    var typeErasedBase64String: String {
        if contains(";base64,") {
            let base64Index = self.firstIndex(of: ",") ?? startIndex
            return String(self[base64Index...self.index(before: self.endIndex)].dropFirst())
        } else {
            return self
        }
    }
}

/// Bidirectional representation for message extensions
public struct MessageExtensionsData: Codable, Hashable {
    init?(_ payloadData: Data) {
        guard let payloadDictionary = try? NSKeyedUnarchiver.unarchivedObject(ofClasses: UnarchivingClasses, from: payloadData) as? NSDictionary else {
            return nil
        }
        
        layoutInfo = MessageExtensionsLayoutInfo(payloadDictionary[IMExtensionPayloadBalloonLayoutInfoKey] as? NSDictionary)
        sessionIdentifier = payloadDictionary[IMExtensionPayloadUserSessionIdentifier] as? UUID
        liveLayoutInfo = payloadDictionary[IMExtensionPayloadBalloonLiveLayoutInfoKey] as? Data
        layoutClass = payloadDictionary[IMExtensionPayloadBalloonLayoutClassKey] as? String
        url = (payloadDictionary[IMExtensionPayloadURLKey] as? URL)?.absoluteString
        data = payloadDictionary[IMExtensionPayloadDataKey] as? Data
        if let dataFilePathData = payloadDictionary[IMExtensionPayloadDataFilePathKey] as? Data {
            dataFilePath = String(data: dataFilePathData, encoding: .utf8)
            
            if var dataFilePath = dataFilePath, data == nil {
                #if os(iOS)
                fatalError("I AM NOT EQUIPPED FOR THIS!!!")
                #else
                if dataFilePath.starts(with: "Library") {
                    dataFilePath.insert(contentsOf: "~/", at: dataFilePath.startIndex)
                }
                #endif
            
                dataFilePath = dataFilePath.expandingTildeInPath
                
                if let data = try? Data(contentsOf: URL(fileURLWithPath: dataFilePath)) {
                    self.data = data
                    
                    if let json = try? JSONSerialization.jsonObject(with: data, options: .init()) {
                        self.payload = AnyCodable(json)
                    }
                }
            }
        }
        accessibilityLabel = payloadDictionary[IMExtensionPayloadAccessibilityLableKey] as? String
        if let rawAppIcon = payloadDictionary[IMExtensionPayloadAppIconKey] as? Data, let appIconData = rawAppIcon.isGzipped ? try? rawAppIcon.gunzipped() : rawAppIcon {
            var base64String = appIconData.base64EncodedString()
            
            /// Resolve the image base64 so it can be directly embedded in an <img src> tag if desired
            if let mimeType = Swime.mimeType(data: appIconData)?.mime {
                base64String.insert(contentsOf: "data:\(mimeType);base64,", at: base64String.startIndex)
            }
            
            appIcon = base64String
        }
        appName = payloadDictionary[IMExtensionPayloadAppNameKey] as? String
        adamIDI = payloadDictionary[IMExtensionPayloadAdamIDIKey] as? String
        statusText = payloadDictionary[IMExtensionPayloadStatusTextKey] as? String
        localizedDescription = payloadDictionary[IMExtensionPayloadLocalizedDescriptionTextKey] as? String
        alternateText = payloadDictionary[IMExtensionPayloadAlternateTextKey] as? String
    }
    
    public var dictionary: NSDictionary {
        let dictionary = NSMutableDictionary()
        
        dictionary[IMExtensionPayloadLocalizedDescriptionTextKey] = localizedDescription as NSString?
        dictionary[IMExtensionPayloadAdamIDIKey] = adamIDI as NSString?
        if let dataFilePath = dataFilePath, let dataFilePathData = dataFilePath.data(using: .utf8) {
            dictionary[IMExtensionPayloadDataFilePathKey] = NSMutableData(data: dataFilePathData)
        }
        dictionary[IMExtensionPayloadAccessibilityLableKey] = accessibilityLabel as NSString?
        dictionary[IMExtensionPayloadUserSessionIdentifier] = sessionIdentifier as NSUUID?
        dictionary[IMExtensionPayloadBalloonLiveLayoutInfoKey] = liveLayoutInfo as NSData?
        dictionary[IMExtensionPayloadBalloonLayoutClassKey] = layoutClass as NSString?
        if let rawURL = url {
            dictionary[IMExtensionPayloadURLKey] = URL(string: rawURL) as NSURL?
        }
        dictionary[IMExtensionPayloadBalloonLayoutInfoKey] = layoutInfo?.dictionary
        if let data = appIconData {
            dictionary[IMExtensionPayloadAppIconKey] = data as NSData
        }
        dictionary[IMExtensionPayloadAppNameKey] = appName as NSString?
        dictionary[IMExtensionPayloadStatusTextKey] = statusText as NSString?
        dictionary[IMExtensionPayloadAlternateTextKey] = alternateText as NSString?
        
        if let data = data as NSData? ?? (synthesizedData as NSData?) {
            dictionary[IMExtensionPayloadDataKey] = data
        }
        
        return dictionary
    }
    
    public var archive: Data {
        let archiver = NSKeyedArchiver(requiringSecureCoding: false)
        archiver.outputFormat = .binary
        
        archiver.encode(dictionary, forKey: "root")
        
        return archiver.encodedData
    }
    
    public var synthesizedData: Data? {
        if let payload = payload?.value {
            return try? JSONSerialization.data(withJSONObject: payload, options: .init())
        }
        return nil
    }
    
    private var appIconData: Data? {
        guard var encoded64 = appIcon?.typeErasedBase64String else {
            return nil
        }
        
        let remainder = encoded64.count % 4
        if remainder > 0 {
            encoded64 = encoded64.padding(toLength: encoded64.count + 4 - remainder,
                                          withPad: "=",
                                          startingAt: 0)
        }
        
        return try? Data(base64Encoded: encoded64)?.gzipped()
    }
    
    public var layoutInfo: MessageExtensionsLayoutInfo?
    public var appIcon: String?
    public var liveLayoutInfo: Data?
    public var layoutClass: String?
    public var url: String?
    public var data: Data?
    public var payload: AnyCodable?
    public var dataFilePath: String?
    public var accessibilityLabel: String?
    public var sessionIdentifier: UUID?
    public var appName: String?
    public var adamIDI: String?
    public var statusText: String?
    public var localizedDescription: String?
    public var alternateText: String?
}

public extension RichLinkMetadata {
    var log: Logging.Logger {
        Logger(label: "RichLinkMetadata")
    }
    init?(extensionData: MessageExtensionsData, attachments: [Attachment], fallbackText: inout String) {
        if let appIcon = extensionData.appIcon, let iconData = Data(base64Encoded: appIcon) {
            icon = RichLinkAsset(mimeType: nil, accessibilityText: nil, source: .data(iconData), originalURL: nil, size: .init(cg: .zero))
        }
        if let appName = extensionData.appName {
            fallbackText = appName + " Message"
        } else {
            fallbackText = extensionData.localizedDescription ?? "Extension Message"
        }
        if let layoutInfo = extensionData.layoutInfo {
            var captions = [extensionData.localizedDescription, layoutInfo.imageTitle, layoutInfo.imageSubtitle, layoutInfo.caption, layoutInfo.subcaption, layoutInfo.secondarySubcaption, layoutInfo.tertiarySubcaption].compactMap { $0 }.filter {
                $0 != title && $0 != fallbackText
            }
            captions.removeDuplicates()
            if title?.isEmpty != false, !captions.isEmpty {
                title = captions.removeFirst()
            }
            var summary = ""
            func push(_ text: String) {
                if text.isEmpty {
                    return
                }
                if !summary.isEmpty {
                    summary += "\r"
                }
                summary += text
            }
            captions.forEach(push(_:))
            if !summary.isEmpty {
                self.summary = summary
            }
        }
        if !attachments.isEmpty {
            for attachment in attachments {
                if let transfer = attachment.existingFileTransfer {
                    guard let guid = transfer.guid else {
                        log.debug("Skipping transfer \(transfer) because it has no GUID?!", source: "LPLink+MSExt")
                        continue
                    }
                    log.info("Transfer \(guid) mime \(transfer.mimeType ?? "nil") isAuxImage \(transfer.isAuxImage)", source: "LPLink+MSExt")
                    guard let type = transfer.type else {
                        log.debug("Skip transfer \(guid) because it is missing a UTI", source: "LPLink+MSExt")
                        continue
                    }
                    guard UTTypeConformsTo(type as CFString, kUTTypeImage) else {
                        log.debug("Skip transfer \(guid) because it is not an image", source: "LPLink+MSExt")
                        continue
                    }
                    guard let localURL = transfer.localURL else {
                        log.info("Skip transfer \(guid) because it has no local URL", source: "LPLink+MSExt")
                        continue
                    }
                    guard let data = CBTranscoding.toJPEG(contentsOf: localURL) else {
                        log.warning("Failed to transcode image to JPEG from \(localURL.absoluteString)", source: "LPLink+MSExt")
                        continue
                    }
                    log.info("Selecting transfer \(guid) for extension data translation", source: "LPLink+MSExt")
                    let size = transfer.mediaSize.map {
                        RichLinkMetadata.RichLinkAsset.Size(width: Double($0.width), height: Double($0.height))
                    }
                    image = .init(mimeType: transfer.mimeType, accessibilityText: nil, source: .data(data), originalURL: nil, size: size)
                    break
                }
            }
        }
        if let url = extensionData.url.flatMap(Foundation.URL.init(string:)), url.scheme != nil {
            self.URL = url
            self.originalURL = url
        }
    }
}
