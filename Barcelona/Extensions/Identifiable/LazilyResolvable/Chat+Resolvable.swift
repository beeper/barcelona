//
//  Chat+Resolvable.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/11/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

extension Chat: Resolvable, _ConcreteBasicResolvable {
    public static func resolve(withIdentifiers identifiers: [String]) -> [Chat] {
        IMChat.resolve(withIdentifiers: identifiers).map { imChat in
            imChat.representation
        }
    }

    public static func resolve(withMessageGUID guid: String) -> Chat? {
        IMChat.resolve(withMessageGUID: guid)?.representation
    }
}
