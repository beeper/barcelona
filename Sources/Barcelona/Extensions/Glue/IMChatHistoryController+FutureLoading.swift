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
    func loadMessage(withGUID guid: String) -> Promise<IMMessage?> {
        Promise { resolve in
            self.loadMessage(withGUID: guid) { message in
                resolve(message)
            }
        }
    }
    
    func loadMessages(withGUIDs guids: [String]) -> Promise<[IMMessage]> {
        return Promise.all(guids.map(loadMessage(withGUID:))).nonnull
    }
}
