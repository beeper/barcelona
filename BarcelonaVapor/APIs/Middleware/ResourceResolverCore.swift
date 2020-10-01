//
//  ResourceResolver.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/11/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import CoreBarcelona
import Vapor

struct ResolvableStorageKey<P>: StorageKey {
    typealias Value = P
}

func APITypeDescriptor<P: Identifiable>(forClazz clazz: P.Type) -> String {
    var itemName = String(describing: clazz)
    if let IMPrefixRange = itemName.range(of: "IM") ?? itemName.range(of: "CN") {
        itemName = String(itemName[IMPrefixRange.upperBound...itemName.index(before: itemName.endIndex)])
    }
    
    return itemName.lowercased()
}

private func NotFoundDescriptor<P: Identifiable>(forClazz clazz: P.Type) -> String {
    "Unknown \(APITypeDescriptor(forClazz: clazz))"
}

func createResolver<P: Resolvable>(clazz: P.Type, parameterKey: String, badRequestError: String = "The ID must be provided.") -> (middleware: FutureMiddleware, storageKey: ResolvableStorageKey<P.instancetype>.Type) {
    let storageKey = ResolvableStorageKey<P.instancetype>.self, notFoundError = NotFoundDescriptor(forClazz: clazz)
    
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

func createLazyResolver<P: LazilyResolvable>(clazz: P.Type, parameterKey: String, badRequestError: String = "The ID must be provided.") -> (middleware: FutureMiddleware, storageKey: ResolvableStorageKey<P.instancetype>.Type) {
    let storageKey = ResolvableStorageKey<P.instancetype>.self, notFoundError = NotFoundDescriptor(forClazz: clazz)
    
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
