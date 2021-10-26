//
//  IMService+Resolvable.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/11/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

extension IMService: Resolvable, _ConcreteBasicResolvable {
    public static func resolve(withIdentifiers identifiers: [IMServiceStyle]) -> [IMService] {
        identifiers.compactMap { style in
            style.service
        }
    }
}
