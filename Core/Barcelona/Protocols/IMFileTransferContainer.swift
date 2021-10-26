//
//  IMFileTransferContainer.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/3/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import os.log

@usableFromInline
protocol IMFileTransferContainer {
    var fileTransferGUIDs: [String] { get }
    var attachments: [Attachment] { get }
    var unloadedFileTransferGUIDs: [String] { get }
    var internalAttachments: [BarcelonaAttachment] { get }
}

extension IMFileTransferContainer {
    @usableFromInline
    var unloadedFileTransferGUIDs: [String] {
        fileTransferGUIDs.filter {
            Attachment(guid: $0) == nil
        }
    }
    
    @usableFromInline
    var attachments: [Attachment] {
        fileTransferGUIDs.compactMap {
            Attachment(guid: $0)
        }
    }
    
    @usableFromInline
    var internalAttachments: [BarcelonaAttachment] {
        BarcelonaAttachment.resolve(withIdentifiers: fileTransferGUIDs)
    }
}
