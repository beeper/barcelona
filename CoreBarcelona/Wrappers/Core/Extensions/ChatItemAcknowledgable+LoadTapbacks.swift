//
//  ChatItem+Tapbacks.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 8/17/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import NIO

extension ChatItemAcknowledgable {
    func tapbacks(on eventLoop: EventLoop) -> EventLoopFuture<[Message]> {
        guard let guid = id as? String else {
            return eventLoop.makeSucceededFuture([])
        }
        
        return DBReader(pool: databasePool, eventLoop: eventLoop).associatedMessages(with: guid)
    }
}
