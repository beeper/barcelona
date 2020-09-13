//
//  InternalAttachment+LazilyResolvable.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/11/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import NIO

extension InternalAttachment: LazilyResolvable, ConcreteLazilyBasicResolvable {
    public static func lazyResolve(withIdentifiers identifiers: [String], on eventLoop: EventLoop?) -> EventLoopFuture<[InternalAttachment]> {
        DBReader(pool: databasePool, eventLoop: eventLoop ?? messageQuerySystem.next()).attachments(withGUIDs: identifiers)
    }
}
