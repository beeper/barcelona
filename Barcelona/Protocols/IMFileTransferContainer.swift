//
//  IMFileTransferContainer.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/3/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import os.log

protocol IMFileTransferContainer {
    var fileTransferGUIDs: [String] { get }
    var attachments: [Attachment] { get }
}

extension IMFileTransferContainer {
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
