//
//  Request+Security.swift
//  BarcelonaVapor
//
//  Created by Eric Rabil on 9/23/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import SwiftJWT
import Vapor

extension Request {
    var token: JWT<JWTClaim>? {
        get {
            storage[JWTStorageKey]
        }
        set {
            storage[JWTStorageKey] = newValue
        }
    }
    
    func hasGrants(_ grants: [TokenGrant]) -> Bool {
        guard let token = token else {
            return false
        }
        
        return grants.allSatisfy {
            token.claims.grants.contains($0)
        }
    }
}
