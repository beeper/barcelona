//
//  IMMessage.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/11/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import NIO

extension IMMessage: LazilyResolvable, ConcreteLazilyBasicResolvable {
    public static func lazyResolve(withIdentifiers identifiers: [String], on eventLoop: EventLoop?) -> EventLoopFuture<[IMMessage]> {
        imMessages(withGUIDs: identifiers, on: eventLoop ?? messageQuerySystem.next())
    }
}
