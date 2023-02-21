//
//  IMPluginChatItem+FileTransferGUIDs.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/3/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

extension IMTranscriptPluginChatItem: IMFileTransferContainer {
    @usableFromInline
    var fileTransferGUIDs: [String] {
        if let rawAttachments = dataSource?.pluginPayload?.value(forKey: "attachments") as? [URL] {
            return rawAttachments.map {
                let components = $0.pathComponents
                return components[components.count - 2]
            }
        }

        return []
    }
}
