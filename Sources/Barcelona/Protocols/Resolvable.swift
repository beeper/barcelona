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

extension Array: Identifiable, Resolvable, _ConcreteBasicResolvable where Element: Resolvable {
    public var id: Element.ID {
        fatalError("Method not implemented.")
    }
    
    public static func resolve(withIdentifiers identifiers: [Element.ID]) -> [Element.instancetype] {
        Element.resolve(withIdentifiers: identifiers)
    }
}

public protocol _ConcreteBasicResolvable: Resolvable {}
extension _ConcreteBasicResolvable {
    public static func resolve(withIdentifier identifier: ID) -> instancetype? {
        resolve(withIdentifiers: [identifier]).first
    }
}
