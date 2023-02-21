//
//  IMMessage.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/11/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

extension IMMessage: LazilyResolvable, ConcreteLazilyBasicResolvable {
    public static func resolveSync(withIdentifiers identifiers: [String]) -> [IMMessage] {
        BLLoadIMMessages(withGUIDs: identifiers)
    }

    public static func resolveSync(withIdentifier identifier: String) -> IMMessage? {
        resolveSync(withIdentifiers: [identifier]).first
    }

    public static func lazyResolve(withIdentifiers identifiers: [String]) -> Promise<[IMMessage]> {
        .success(resolveSync(withIdentifiers: identifiers))
    }
}
