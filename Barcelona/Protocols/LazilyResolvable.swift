//
//  LazilyIdentifiable.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/11/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation

public protocol LazilyResolvable: Identifiable {
    associatedtype instancetype
    typealias BulkResult = Promise<[instancetype]>
    
    static func lazyResolve(withIdentifier identifier: ID) -> Promise<instancetype?>
    static func lazyResolve(withIdentifiers identifiers: [ID]) -> BulkResult
}

internal protocol ConcreteLazilyBasicResolvable: LazilyResolvable {}
extension ConcreteLazilyBasicResolvable {
    public static func lazyResolve(withIdentifier identifier: ID) -> Promise<instancetype?> {
        lazyResolve(withIdentifiers: [identifier]).first
    }
}
