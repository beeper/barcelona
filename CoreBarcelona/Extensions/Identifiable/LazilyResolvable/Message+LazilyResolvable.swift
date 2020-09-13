//
//  Message+LazilyResolvable.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/11/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import NIO

extension Message: LazilyResolvable, ConcreteLazilyBasicResolvable {
    public static func lazyResolve(withIdentifiers identifiers: [String], on eventLoop: EventLoop?) -> EventLoopFuture<[Message]> {
        lazyResolve(withIdentifiers: identifiers, inChat: nil, on: eventLoop)
    }
    
    public static func lazyResolve(withIdentifiers identifiers: [String], inChat chat: String?, on eventLoop: EventLoop?) -> EventLoopFuture<[Message]> {
        messages(withGUIDs: identifiers, in: chat, on: eventLoop ?? messageQuerySystem.next())
    }
}
