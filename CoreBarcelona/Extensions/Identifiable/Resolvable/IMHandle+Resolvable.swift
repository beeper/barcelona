//
//  IMHandle+Resolvable.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/14/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

extension IMHandle: Resolvable, ConcreteBasicResolvable {
    public static func resolve(withIdentifiers identifiers: [String]) -> [IMHandle] {
        identifiers.compactMap {
            Registry.sharedInstance.imHandle(withID: $0)
        }
    }
}
