//
//  IMFileTransfer+Bridging.swift
//  Barcelona
//
//  Created by Eric Rabil on 11/2/21.
//

import Foundation
import IMSharedUtilities
import CoreGraphics
import AVFoundation

internal extension IMFileTransfer {
    var ensuredUTI: CFString? {
        if let uti = type {
            return uti as CFString
        } else if let mime = mimeType {
            return UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mime as CFString, nil)?.takeRetainedValue()
        } else {
            return nil
        }
    }
    
    var ensuredLocalPath: String? {
        if let localPath = localPath {
            return localPath
        }
        
        if let path = BLLoadAttachmentPathForTransfer(withGUID: guid) {
            self.localPath = path
            return path
        }
        
        return nil
    }
    
    var ensuredLocalURL: URL! {
        if let localURL = localURL {
            return localURL
        }
        
        if let localPath = ensuredLocalPath {
            return URL(fileURLWithPath: localPath)
        }
        
        return nil
    }
    
    func ensureLocalPath() {
        guard localPath != nil else {
            self.localPath = self.ensuredLocalPath
            return
        }
    }
    
    var mediaSize: Size? {
        guard let uti = ensuredUTI else {
            return nil
        }
        
        if UTTypeConformsTo(uti, kUTTypeVideo) || UTTypeConformsTo(uti, kUTTypeMovie) {
            guard let track = AVURLAsset(url: ensuredLocalURL).tracks(withMediaType: .video).first else {
                return nil
            }
            
            let size = track.naturalSize.applying(track.preferredTransform)
            return .init(cgSize: size)
        } else if UTTypeConformsTo(uti, kUTTypeImage) {
            guard let source = CGImageSourceCreateWithURL(ensuredLocalURL as CFURL, nil) else {
                return nil
            }
            
            let propertiesOptions = [kCGImageSourceShouldCache: false] as CFDictionary
            guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, propertiesOptions) as? [CFString: Any] else {
                return nil
            }
            
            if let width = properties[kCGImagePropertyWidth] as? CGFloat, let height = properties[kCGImagePropertyHeight] as? CGFloat {
                return .init(width: width, height: height)
            } else if let width = properties[kCGImagePropertyPixelWidth] as? CGFloat, let height = properties[kCGImagePropertyPixelHeight] as? CGFloat {
                return .init(width: width, height: height)
            }
        }
        
        return nil
    }
}
