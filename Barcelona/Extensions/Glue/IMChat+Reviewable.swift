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

public extension IMChat {
    func scheduleForReview() {
        DispatchQueue.main.async {
            self._updateChatItems()
            os_log("Updated chat items for ChatID %@", type: .debug, self.id, log_IMChat)
        }
    }
}
