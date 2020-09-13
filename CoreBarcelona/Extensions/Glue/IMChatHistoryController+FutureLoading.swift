//
//  IMChatHistoryController+FutureLoading.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/12/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import NIO

extension IMChatHistoryController {
    func loadMessage(withGUID guid: String, on eventLoop: EventLoop = messageQuerySystem.next()) -> EventLoopFuture<IMMessage?> {
        let promise = eventLoop.makePromise(of: IMMessage?.self)
        
        loadMessage(withGUID: guid) { message in
            promise.succeed(message)
        }
        
        return promise.futureResult
    }
    
    func loadMessages(withGUIDs guids: [String], on eventLoop: EventLoop = messageQuerySystem.next()) -> EventLoopFuture<[IMMessage]> {
        return EventLoopFuture<IMMessage?>.whenAllSucceed(guids.map {
            loadMessage(withGUID: $0, on: eventLoop)
        }, on: eventLoop).map {
            $0.compactMap { $0 }
        }
    }
}
