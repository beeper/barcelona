//
//  IMFileTransfer+InternalAttachment.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/12/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

extension IMFileTransfer {
    var internalAttachment: BarcelonaAttachment {
        BarcelonaAttachment(guid: guid, originalGUID: originalGUID, path: localPath, bytes: totalBytes, incoming: isIncoming, mime: mimeType)
    }
}
