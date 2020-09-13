//
//  ResourceResolver.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/11/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import Vapor

struct ResolvableStorageKey<P>: StorageKey {
    typealias Value = P
}

func createResolver<P: Resolvable>(clazz: P.Type, parameterKey: String, badRequestError: String = "The ID must be provided.", notFoundError: String = "Unknown resource") -> (middleware: FutureMiddleware, storageKey: ResolvableStorageKey<P.instancetype>.Type) {
    let storageKey = ResolvableStorageKey<P.instancetype>.self
    
    return (middleware: FutureMiddleware { req, next in
        guard let id = req.parameters.get(parameterKey) as? P.ID else {
            return req.eventLoop.makeFailedFuture(Abort(.badRequest, reason: badRequestError))
        }
        
        guard let resource = P.resolve(withIdentifier: id) else {
            return req.eventLoop.makeFailedFuture(Abort(.notFound, reason: notFoundError))
        }
        
        req.storage[storageKey] = resource
        
        return next.respond(to: req)
    }, storageKey: storageKey)
}

func createLazyResolver<P: LazilyResolvable>(clazz: P.Type, parameterKey: String, badRequestError: String = "The ID must be provided.", notFoundError: String = "Unknown resource") -> (middleware: FutureMiddleware, storageKey: ResolvableStorageKey<P.instancetype>.Type) {
    let storageKey = ResolvableStorageKey<P.instancetype>.self
    
    return (middleware: FutureMiddleware { req, next in
        guard let id = req.parameters.get(parameterKey) as? P.ID else {
            return req.eventLoop.makeFailedFuture(Abort(.badRequest, reason: badRequestError))
        }
        
        return P.lazyResolve(withIdentifier: id, on: req.eventLoop).flatMap { resource in
            guard let resource = resource else {
                return req.eventLoop.makeFailedFuture(Abort(.notFound, reason: notFoundError))
            }
            
            req.storage[storageKey] = resource
            
            return next.respond(to: req)
        }
    }, storageKey: storageKey)
}
