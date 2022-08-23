//
//  IMAttachmentMessagePartChatItem+IMFileTransferContainer.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/3/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

extension IMAttachmentMessagePartChatItem: IMFileTransferContainer {
    @usableFromInline
    var fileTransferGUIDs: [String] {
        [self.transferGUID]
    }
}
