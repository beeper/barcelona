//
//  CNContact+LazilyResolvable.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/11/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import Contacts
import NIO

extension CNContact: LazilyResolvable, ConcreteLazilyBasicResolvable {
    public static func lazyResolve(withIdentifiers identifiers: [String], on eventLoop: EventLoop?) -> EventLoopFuture<[CNContact]> {
        (eventLoop ?? messageQuerySystem.next()).submit {
            CNContact.resolve(withIdentifiers: identifiers)
        }
    }
}
