//
//  IMChatHistoryController+FutureLoading.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/12/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

extension IMChatHistoryController {
    func loadMessage(withGUID guid: String) async -> IMMessage? {
        await withCheckedContinuation { continuation in
            self.loadMessage(withGUID: guid) { message in
                continuation.resume(returning: message)
            }
        }
    }

    func loadMessages(withGUIDs guids: [String]) async -> [IMMessage] {
        await guids.asyncMap {
            await self.loadMessage(withGUID: $0)
        }
        .compactMap { $0 }
    }
}
