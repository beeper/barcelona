//
//  LazilyIdentifiable.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/11/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import NIO

public protocol LazilyResolvable: Identifiable {
    associatedtype instancetype
    typealias BulkResult = EventLoopFuture<[instancetype]>
    
    static func lazyResolve(withIdentifier identifier: ID, on eventLoop: EventLoop?) -> EventLoopFuture<instancetype?>
    static func lazyResolve(withIdentifier identifier: ID) -> EventLoopFuture<instancetype?>
    static func lazyResolve(withIdentifiers identifiers: [ID], on eventLoop: EventLoop?) -> BulkResult
    static func lazyResolve(withIdentifiers identifiers: [ID]) -> BulkResult
}

internal protocol ConcreteLazilyBasicResolvable: LazilyResolvable {}
extension ConcreteLazilyBasicResolvable {
    public static func lazyResolve(withIdentifier identifier: ID, on eventLoop: EventLoop?) -> EventLoopFuture<instancetype?> {
        lazyResolve(withIdentifiers: [identifier], on: eventLoop).map {
            $0.first
        }
    }
    
    public static func lazyResolve(withIdentifier identifier: ID) -> EventLoopFuture<instancetype?> {
        lazyResolve(withIdentifier: identifier, on: nil)
    }
    
    public static func lazyResolve(withIdentifiers identifiers: [ID]) -> BulkResult {
        lazyResolve(withIdentifiers: identifiers, on: nil)
    }
}
