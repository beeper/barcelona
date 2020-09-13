//
//  Attachment.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/11/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

struct Attachment: Codable {
    init(_ transfer: IMFileTransfer) {
        mime = transfer.mimeType
        filename = transfer.filename
        id = transfer.guid
        uti = transfer.type
    }
    
    init?(guid: String) {
        guard let item = IMFileTransferCenter.sharedInstance()?.transfer(forGUID: guid, includeRemoved: false) else {
            return nil
        }
        
        self.init(item)
    }
    
    var mime: String?
    var filename: String?
    var id: String?
    var uti: String?
}

private func ERRegisterFileTransferForGUID(transfer: IMFileTransfer, guid: String) {
    let center = IMFileTransferCenter.sharedInstance()!
    
    if let map = center.value(forKey: "_guidToTransferMap") as? NSDictionary {
        map.setValue(transfer, forKey: guid)
    }
    
    center.registerTransfer(withDaemon: guid)
}

public struct InternalAttachment {
    var guid: String
    var originalGUID: String?
    var path: String
    var bytes: UInt64
    var incoming: Bool
    var mime: String?
    
    private var account: IMAccount {
        Registry.sharedInstance.iMessageAccount()!
    }
    
    private var transferCenter: IMFileTransferCenter {
        IMFileTransferCenter.sharedInstance()!
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
