//
//  BLAttachment.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 5/24/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import Barcelona

public typealias BLAttachment = PBAttachment

import BarcelonaMautrixIPCProtobuf

public extension PBAttachment {
    init?(_ attachment: Attachment) {
        guard let path = attachment.path else {
            return nil
        }
        self = .with { `self` in
            self.guid = attachment.id
            self.fileName = attachment.name
            self.pathOnDisk = path
            attachment.mime.map { mime in
                self.mimeType = mime
            }
        }
    }
    
    init?(guid: String) {
        guard let attachment = Attachment(guid: guid) else {
            return nil
        }
        self.init(attachment)
    }
}
