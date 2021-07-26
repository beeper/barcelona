//
//  Attachment.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/11/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import AVFoundation
import ImageIO
import CoreServices
import Swime
import IMDPersistence

public struct BulkAttachmentRepresentation: Codable {
    public init(attachments: [Attachment]) {
        self.attachments = attachments
    }
    
    public var attachments: [Attachment]
}

public struct ResourceOrigin: Codable, Hashable {
    public init?(chatID: String? = nil, handleID: String? = nil, date: Double? = nil) {
        self.chatID = chatID
        self.handleID = handleID
        self.date = date
        
        if chatID == nil, handleID == nil, date == nil {
            return nil
        }
    }
    
    public var chatID: String?
    public var handleID: String?
    public var date: Double?
}

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
        
        if let path = CBLoadAttachmentPathForTransfer(withGUID: guid) {
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

public struct Attachment: Codable, Hashable {
    public init(mime: String? = nil, filename: String? = nil, id: String, uti: String? = nil, origin: ResourceOrigin? = nil, size: Size? = nil, sticker: StickerInformation? = nil) {
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
    public var filename: String?
    public var id: String
    public var uti: String?
    public var origin: ResourceOrigin?
    public var size: Size?
    public var sticker: StickerInformation?
    
    public var path: String? {
        IMFileTransferCenter.sharedInstance().transfer(forGUID: id, includeRemoved: false)?.localPath ?? CBLoadAttachmentPathForTransfer(withGUID: id)
    }
}

private func CBUTIType(ofMimeType mimeType: String) -> String {
    IMFileManager.defaultHFS()!.utiType(ofMimeType: mimeType) as! String
}

internal func CBPersistentFileTransferPath(for transfer: IMFileTransfer, filename: String, highQuality: Bool) -> String {
    if #available(iOS 14, macOS 10.16, watchOS 7, *) {
        return IMDPersistentAttachmentController.sharedInstance()._persistentPath(for: transfer, filename: filename, highQuality: highQuality, chatGUID: nil, storeAtExternalPath: nil)
    } else {
        return IMDPersistentAttachmentController.sharedInstance()._persistentPath(for: transfer, filename: filename, highQuality: highQuality)
    }
}

internal func CBPersistentFileTransferURL(for transfer: IMFileTransfer, filename: String, highQuality: Bool) -> URL {
    return URL(fileURLWithPath: CBPersistentFileTransferPath(for: transfer, filename: filename, highQuality: highQuality))
}

internal func CBAdaptPersistentPathToStoredPath(_ persistentPath: String) -> String {
    #if os(macOS)
    return "~/\(persistentPath.split(separator: "/")[2...].joined(separator: "/"))"
    #else
    return persistentPath
    #endif
}

internal func CBEnsureFileTransferContainerExists(_ containerURL: URL) throws {
    try FileManager.default.createDirectory(at: containerURL.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
}

internal func CBRegisterFileTransferWithDaemon(_ transfer: IMFileTransfer, forService service: IMServiceStyle) {
    IMFileTransferCenter.sharedInstance()._addTransfer(transfer, toAccount: service.account)
    
    if let map = IMFileTransferCenter.sharedInstance().value(forKey: "_guidToTransferMap") as? NSDictionary {
        map.setValue(transfer, forKey: transfer.guid)
    }
    
    IMFileTransferCenter.sharedInstance().registerTransfer(withDaemon: transfer)
}

public func CBInitializeFileTransfer(withMimeType mimeType: String, forService service: IMServiceStyle, filename: String, path: URL, bytes: UInt64? = nil) -> Promise<IMFileTransfer, Error> {
    Promise { () -> IMFileTransfer in
        let guid = NSString.stringGUID()
        
        guard let bytes = bytes ?? (try? FileManager.default.attributesOfItem(atPath: path.path)[.size] as? UInt64) else {
            throw BarcelonaError(code: 500, message: "Failed to measure size of file")
        }
        
        let transfer = IMFileTransfer()._init(withGUID: guid, filename: filename, isDirectory: false, localURL: path, account: service.account, otherPerson: nil, totalBytes: bytes, hfsType: 0, hfsCreator: 0, hfsFlags: 0, isIncoming: false)!
        
        transfer.setValue(mimeType, forKey: "_mimeType")
        transfer.setValue(CBUTIType(ofMimeType: mimeType), forKey: "_utiType")
        
        let persistentPath = CBPersistentFileTransferURL(for: transfer, filename: filename, highQuality: true)
        try CBEnsureFileTransferContainerExists(persistentPath)
        
        try FileManager.default.copyItem(at: path, to: persistentPath)
        
        transfer.localURL = persistentPath
        transfer.filename = filename
        transfer.transferredFilename = filename
        
        CBRegisterFileTransferWithDaemon(transfer, forService: service)
        
        return transfer
    }.then { transfer in
        transfer.saveToDatabase(atPath: CBAdaptPersistentPathToStoredPath(transfer.localPath)).map { _ in
            transfer
        }
    }
}

private func ERRegisterFileTransferForGUID(transfer: IMFileTransfer, guid: String) {
    let center = IMFileTransferCenter.sharedInstance()
    
    if let map = center.value(forKey: "_guidToTransferMap") as? NSDictionary {
        map.setValue(transfer, forKey: guid)
    }
    
    center.registerTransfer(withDaemon: guid)
}

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

public struct InternalAttachment {
    public var guid: String
    public var originalGUID: String?
    public var path: String
    public var bytes: UInt64
    public var incoming: Bool
    public var mime: String?
    public var uti: String?
    public var origin: ResourceOrigin?
    
    private var account: IMAccount {
        Registry.sharedInstance.iMessageAccount()!
    }
    
    private var transferCenter: IMFileTransferCenter {
        IMFileTransferCenter.sharedInstance()
    }
    
    private var url: URL {
        URL(fileURLWithPath: path)
    }
    
    private var filename: String {
        url.lastPathComponent
    }
    
    var attachment: Attachment {
        Attachment(mime: self.mime, filename: filename, id: guid, uti: uti, origin: origin, size: fileTransfer.mediaSize, sticker: fileTransfer.isSticker ? .init(fileTransfer.stickerUserInfo) : nil)
    }
    
    func registerFileTransferIfNeeded() {
        let _ = fileTransfer
    }
    
    var fileTransfer: IMFileTransfer {
        if let transfer = transferCenter.transfer(forGUID: guid) {
            guard let originalGUID = originalGUID, transferCenter.transfer(forGUID: originalGUID) == nil else {
                return transfer
            }
        }
        
        let url = URL.init(fileURLWithPath: path)
        let transfer = IMFileTransfer()._init(withGUID: guid, filename: url.lastPathComponent, isDirectory: false, localURL: url, account: account.uniqueID, otherPerson: nil, totalBytes: bytes, hfsType: 0, hfsCreator: 0, hfsFlags: 0, isIncoming: false)!
        
        transfer.transferredFilename = url.lastPathComponent
        
        if let mime = mime {
            transfer.setValue(mime, forKey: "_mimeType")
            transfer.setValue(IMFileManager.defaultHFS()!.utiType(ofMimeType: mime), forKey: "_utiType")
        }
        
        IMFileTransferCenter.sharedInstance()._addTransfer(transfer, toAccount: account.uniqueID)
        
        ERRegisterFileTransferForGUID(transfer: transfer, guid: guid)
        
        if let originalGUID = originalGUID {
            ERRegisterFileTransferForGUID(transfer: transfer, guid: originalGUID)
        }
        
        return transfer
    }
}

extension InternalAttachment {
    init?(guid: String) {
        guard let transfer = IMFileTransferCenter.sharedInstance().transfer(forGUID: guid) else {
            return nil
        }
        
        self.init(guid: guid, originalGUID: transfer.originalGUID, path: transfer.localPath, bytes: transfer.totalBytes, incoming: transfer.isIncoming, mime: transfer.mimeType)
    }
}
