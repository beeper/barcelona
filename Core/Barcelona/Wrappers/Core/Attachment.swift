//
//  Attachment.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/11/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import BarcelonaDB
import IMCore

public struct Size: Codable, Hashable {
    public var width: Float
    public var height: Float
    
    public init(cgSize: CGSize) {
        width = abs(Float(cgSize.width))
        height = abs(Float(cgSize.height))
    }
    
    public init(width: CGFloat, height: CGFloat) {
        self.width = abs(Float(width))
        self.height = abs(Float(height))
    }
}

public struct Attachment: Codable, Hashable {
    public init(mime: String? = nil, filename: String, id: String, uti: String? = nil, origin: ResourceOrigin? = nil, size: Size? = nil, sticker: StickerInformation? = nil) {
        self.mime = mime
        self.filename = filename
        self.id = id
        self.uti = uti
        self.origin = origin
        self.size = size
        self.sticker = sticker
    }
    
    public init(_ transfer: IMFileTransfer) {
        transfer.ensureLocalPath()
        
        mime = transfer.mimeType
        filename = transfer.filename
        id = transfer.guid
        uti = transfer.type
        size = transfer.mediaSize
        
        if transfer.isSticker {
            sticker = StickerInformation(transfer.stickerUserInfo)
        } else {
            sticker = nil
        }
    }
    
    public init?(guid: String) {
        guard let item = IMFileTransferCenter.sharedInstance().transfer(forGUID: guid, includeRemoved: false), item.ensuredLocalPath != nil else {
            return nil
        }
        
        self.init(item)
    }
    
    public var mime: String?
    public var filename: String
    public var id: String
    public var originalGUID: String?
    public var uti: String?
    public var origin: ResourceOrigin?
    public var size: Size?
    public var sticker: StickerInformation?
    
    public var url: URL {
        URL(fileURLWithPath: filename)
    }
    
    public var name: String {
        url.lastPathComponent
    }
    
    public var path: String {
        url.path
    }
    
    public var fileTransfer: IMFileTransfer {
        BLLoadFileTransfer(withGUID: id) ?? CBInitializeFileTransfer(filename: url.lastPathComponent, path: url)
    }
}

internal extension Attachment {
    @usableFromInline func registerFileTransferIfNeeded() {
        _ = fileTransfer
    }
}
