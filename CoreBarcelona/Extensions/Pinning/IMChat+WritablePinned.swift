//
//  IMChat+WritablePinned.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 2/13/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import IMCore

public extension IMChat {
    var pinned: Bool {
        get {
            if #available(iOS 14, macOS 10.16, watchOS 7, *) {
                return isPinned
            } else {
                return false
            }
        }
        set {
            if newValue == pinned {
                return
            }
            if #available(iOS 14, macOS 10.16, watchOS 7, *) {
                newValue ? IMPinnedConversationsController.sharedInstance().pin(chat: self) : IMPinnedConversationsController.sharedInstance().unpin(chat: self)
            }
        }
    }
}
