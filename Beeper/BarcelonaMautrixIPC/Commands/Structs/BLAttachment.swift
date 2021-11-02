//
//  BLAttachment.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 5/24/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import Barcelona

public struct BLAttachment: Codable {
    public var mime_type: String?
    public var file_name: String
    public var path_on_disk: String
    
    public init?(guid: String) {
        guard let attachment = Attachment(guid: guid) else {
            return nil
        }
        
        mime_type = attachment.mime
        file_name = attachment.name
        path_on_disk = attachment.path
    }
}
