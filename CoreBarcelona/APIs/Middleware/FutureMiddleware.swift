//
//  ResourcePreloader.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/11/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import Vapor

class FutureMiddleware: Middleware {
    typealias MiddlewareFunction = (Request, Responder) -> EventLoopFuture<Response>
    
    init(_ handler: @escaping MiddlewareFunction) {
        self.handler = handler
    }
    
    let handler: MiddlewareFunction
    
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        handler(request, next)
    }
}
