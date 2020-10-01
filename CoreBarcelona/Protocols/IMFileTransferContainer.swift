//
//  IMFileTransferContainer.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/3/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import NIO
import os.log

protocol IMFileTransferContainer {
    var fileTransferGUIDs: [String] { get }
    var attachments: [Attachment] { get }
    func preloadFileTransfers() -> EventLoopFuture<Void>
}

func ERPreloadFileTransfers(withGUIDs guids: [String]) -> EventLoopFuture<Void> {
    os_log("Preloading file transfers for GUIDs %@", log: .default, type: .info, guids)
    
    return DBReader.shared.attachments(withGUIDs: guids).map {
        $0.map {
            $0.fileTransfer
        }
    }.map { _ in
        
    }
}

extension IMFileTransferContainer {
    func preloadFileTransfers() -> EventLoopFuture<Void> {
        ERPreloadFileTransfers(withGUIDs: unloadedFileTransferGUIDs)
    }
    
    var unloadedFileTransferGUIDs: [String] {
        fileTransferGUIDs.filter {
            Attachment(guid: $0) == nil
        }
    }
    
    var attachments: [Attachment] {
        fileTransferGUIDs.compactMap {
            Attachment(guid: $0)
        }
    }
    
    var internalAttachments: [InternalAttachment] {
        InternalAttachment.resolve(withIdentifiers: fileTransferGUIDs)
    }
}
