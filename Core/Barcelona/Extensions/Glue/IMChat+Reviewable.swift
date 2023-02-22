//
//  IMChat+Reviewable.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 8/21/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import os.log

extension IMChat {
    public func scheduleForReview() {
        RunLoop.main.schedule {
            self._updateChatItems()
            log_IMChat.debug("updated chat items for chatID \(self.chatIdentifier)")
        }
    }
}
