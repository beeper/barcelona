//
//  IMChat+Reviewable.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 8/21/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

extension IMChat {
    func scheduleForReview() {
        messageQuerySystem.next().submit {
            self._updateChatItems()
        }
    }
}
