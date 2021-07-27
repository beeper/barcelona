//
//  ChatItem+Tapbacks.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 8/17/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation

extension ChatItemAcknowledgable {
    func tapbacks() -> Promise<[Message], Error> {
        return DBReader(pool: databasePool).associatedMessages(with: id)
    }
}
