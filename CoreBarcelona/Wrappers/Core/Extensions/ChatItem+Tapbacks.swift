//
//  ChatItem+Tapbacks.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 8/17/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import NIO

extension ChatItemRepresentation {
    func tapbacks(on eventLoop: EventLoop) -> EventLoopFuture<[Message]> {
        let promise = eventLoop.makePromise(of: [Message].self)
        
        guard let guid = guid else {
            promise.succeed([])
            return promise.futureResult
        }
        
        DBReader(pool: databasePool, eventLoop: eventLoop).associatedMessages(with: guid).whenComplete { result in
            switch result {
            case .success(let tapbacks):
                promise.succeed(tapbacks)
                break
            case .failure(let error):
                promise.fail(error)
                break
            }
        }
        
        return promise.futureResult
    }
}
