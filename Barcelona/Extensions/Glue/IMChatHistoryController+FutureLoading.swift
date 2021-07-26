//
//  IMChatHistoryController+FutureLoading.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/12/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import Combine

extension IMChatHistoryController {
    func loadMessage(withGUID guid: String) -> Promise<IMMessage?, Error> {
        Promise { resolve in
            self.loadMessage(withGUID: guid) { message in
                resolve(message)
            }
        }
    }
    
    func loadMessages(withGUIDs guids: [String]) -> Promise<[IMMessage], Error> {
        return Promise(backing: Publishers.MergeMany(guids.map {
            loadMessage(withGUID: $0)
        }).compactMap { $0 }.collect())
    }
}
