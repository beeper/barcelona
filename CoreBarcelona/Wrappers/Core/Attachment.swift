//
//  Attachment.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/11/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

public struct BulkAttachmentRepresentation: Codable {
    public init(attachments: [Attachment]) {
        self.attachments = attachments
    }
    
    public var attachments: [Attachment]
}

public struct ResourceOrigin: Codable {
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

public struct Attachment: Codable {
    internal init(mime: String? = nil, filename: String? = nil, id: String, uti: String? = nil, origin: ResourceOrigin? = nil) {
        self.mime = mime
        self.filename = filename
        self.id = id
        self.uti = uti
        self.origin = origin
    }
    
    public init(_ transfer: IMFileTransfer) {
        mime = transfer.mimeType
        filename = transfer.filename
        id = transfer.guid
        uti = transfer.type
    }
    
    public init?(guid: String) {
        guard let item = IMFileTransferCenter.sharedInstance()?.transfer(forGUID: guid, includeRemoved: false) else {
            return nil
        }
        
        self.init(item)
    }
    
    public var mime: String?
    public var filename: String?
    public var id: String
    public var uti: String?
    public var origin: ResourceOrigin?
}

private func ERRegisterFileTransferForGUID(transfer: IMFileTransfer, guid: String) {
    let center = IMFileTransferCenter.sharedInstance()!
    
    if let map = center.value(forKey: "_guidToTransferMap") as? NSDictionary {
        map.setValue(transfer, forKey: guid)
    }
    
    center.registerTransfer(withDaemon: guid)
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
        IMFileTransferCenter.sharedInstance()!
    }
    
    private var url: URL {
        URL(fileURLWithPath: path)
    }
    
    private var filename: String {
        url.lastPathComponent
    }
    
    var attachment: Attachment {
        Attachment(mime: self.mime, filename: filename, id: guid, uti: uti, origin: origin)
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
        
        IMFileTransferCenter.sharedInstance()!._addTransfer(transfer, toAccount: account.uniqueID)
        
        ERRegisterFileTransferForGUID(transfer: transfer, guid: guid)
        
        if let originalGUID = originalGUID {
            ERRegisterFileTransferForGUID(transfer: transfer, guid: originalGUID)
        }
        
        return transfer
    }
}

extension InternalAttachment {
    init?(guid: String) {
        guard let transfer = IMFileTransferCenter.sharedInstance()!.transfer(forGUID: guid) else {
            return nil
        }
        
        self.init(guid: guid, originalGUID: transfer.originalGUID, path: transfer.localPath, bytes: transfer.totalBytes, incoming: transfer.isIncoming, mime: transfer.mimeType)
    }
}
