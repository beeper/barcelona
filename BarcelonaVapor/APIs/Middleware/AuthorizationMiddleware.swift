//
//  AuthenticationMiddleware.swift
//  BarcelonaVapor
//
//  Created by Eric Rabil on 9/22/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import CoreBarcelona
import Vapor

protocol Authorizor {
    func validate(headers: HTTPHeaders, request: Request) -> Bool
}

class CompositeAuthorizationMiddleware: Middleware, Authorizor {
    init(authorizors: [Authorizor]) {
        self.authorizors = authorizors
    }
    
    let authorizors: [Authorizor]
    
    func validate(headers: HTTPHeaders, request: Request) -> Bool {
        authorizors.contains(where: {
            $0.validate(headers: headers, request: request)
        })
    }
    
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        #if BARCELONA_NO_SECURITY
        if true {
            return next.respond(to: request)
        }
        #else
        if validate(headers: request.headers, request: request) {
            return next.respond(to: request)
        }
        #endif
        
        return request.eventLoop.makeFailedFuture(BarcelonaError(code: 401, message: "Invalid or missing API token"))
    }
}

class GeneralJWTAuthorizor: Authorizor {
    func validate(headers: HTTPHeaders, request: Request) -> Bool {
        if let authorization = headers.first(name: "authorization"), let token = JWTManager.sharedInstance.validateToken(authorization, forScenario: .general) {
            request.token = token
            
            return true
        }
        
        return false
    }
}

class AttachmentJWTAuthorizor: Authorizor {
    func validate(headers: HTTPHeaders, request: Request) -> Bool {
        if let cookie = headers.cookie, let authorization = cookie[AttachmentsCookieName], JWTManager.sharedInstance.validateToken(authorization.string, forScenario: .attachments) != nil {
            return true
        }
        
        return false
    }
}

extension Authorizor {
    func compositing(_ authorizors: [Authorizor]) -> CompositeAuthorizationMiddleware {
        var authorizors = authorizors
        authorizors.append(self)
        
        return CompositeAuthorizationMiddleware(authorizors: authorizors)
    }
    
    func compositing(_ authorizor: Authorizor) -> CompositeAuthorizationMiddleware {
        return compositing([authorizor])
    }
}
