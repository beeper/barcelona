//
//  InternalAttachment+Resolvable.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/13/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation

extension InternalAttachment: Resolvable, _ConcreteBasicResolvable {
    public static func resolve(withIdentifiers identifiers: [String]) -> [InternalAttachment] {
        identifiers.compactMap {
            InternalAttachment(guid: $0)
        }
    }
}
