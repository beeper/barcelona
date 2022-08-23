//
//  IMChatItem+Identifiable.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 12/17/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

extension IMChatItem: Identifiable {
    public var id: String {
        if let transcriptChatItem = self as? IMTranscriptChatItem {
            return transcriptChatItem.guid
        } else {
            return self._item()!.guid!
        }
    }
}
