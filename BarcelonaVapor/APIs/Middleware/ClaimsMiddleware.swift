//
//  ClaimsMiddleware.swift
//  BarcelonaVapor
//
//  Created by Eric Rabil on 9/23/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import CoreBarcelona
import Vapor

class ClaimsMiddleware: Middleware {
    init(requiredGrants: [TokenGrant]) {
        self.requiredGrants = requiredGrants
    }
    
    let requiredGrants: [TokenGrant]
    
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        respondToJWTClaimValidation(request, chainingTo: next, requiredGrants: requiredGrants)
    }
}
