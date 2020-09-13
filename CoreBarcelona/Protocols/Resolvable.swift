//
//  Resolvable.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/11/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation

public protocol Resolvable: Identifiable {
    associatedtype instancetype
    
    static func resolve(withIdentifier identifier: ID) -> instancetype?
    static func resolve(withIdentifiers identifiers: [ID]) -> [instancetype]
}

internal protocol ConcreteBasicResolvable: Resolvable {}
extension ConcreteBasicResolvable {
    public static func resolve(withIdentifier identifier: ID) -> instancetype? {
        resolve(withIdentifiers: [identifier]).first
    }
}
