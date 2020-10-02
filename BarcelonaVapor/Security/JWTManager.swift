//
//  JWTManager.swift
//  BarcelonaVapor
//
//  Created by Eric Rabil on 9/22/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import CoreBarcelona
import BarcelonaFoundation
import Security
import BCrypt
import SwiftJWT
import os.log
import Vapor

private let jwtKey = "jwt-signing-key"
private let attachmentsKey = "jwt-attachments-signing-key"

internal let ATTACHMENTS_EXPIRATION_SECONDS: Double = 24 * 60 * 60

internal enum SigningScenario {
    case attachments
    case general
    
    var expiration: Date? {
        switch self {
        case .attachments:
            return Date().addingTimeInterval(ATTACHMENTS_EXPIRATION_SECONDS)
        default:
            return nil
        }
    }
}

internal func respondToJWTClaimValidation(_ request: Request, chainingTo next: Responder, requiredGrants: [TokenGrant]) -> EventLoopFuture<Response> {
    #if BARCELONA_NO_SECURITY
    #else
    guard let token = request.token else {
        return request.eventLoop.makeFailedFuture(BarcelonaError(code: 401, message: "Missing API token"))
    }
    
    guard token.conforms(toGrants: requiredGrants) else {
        return request.eventLoop.makeFailedFuture(BarcelonaError(code: 403, message: "Missing grants"))
    }
    #endif
    
    return next.respond(to: request)
}

public enum TokenGrant: String, Middleware, Codable, CaseIterable {
    /** The human grant is required to allow one to change the password */
    case human
    /** use the streaming API */
    case streaming
    /** use the debugging API */
    case debugging
    /** read chat data */
    case readChats
    /** modify, create, delete chats*/
    case writeChats
    /** read contacts data */
    case readContacts
    /** modify, create, delete contacts */
    case writeContacts
    /** read messages data */
    case readMessages
    /** modify, create, delete messages */
    case writeMessages
    /** read attachments data */
    case readAttachments
    /** modify, create, delete attachments*/
    case writeAttachments
    
    fileprivate var canCreateTokens: Bool {
        self == .human
    }
    
    static var botGrants: [TokenGrant] {
        allCases.filter {
            $0 != .human
        }
    }
    
    var middleware: ClaimsMiddleware {
        .init(requiredGrants: [self])
    }
    
    public func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        respondToJWTClaimValidation(request, chainingTo: next, requiredGrants: [self])
    }
}

extension Array: Middleware where Element == TokenGrant {
    public func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        respondToJWTClaimValidation(request, chainingTo: next, requiredGrants: self)
    }
    
    fileprivate var canCreateTokens: Bool {
        contains(.human)
    }
    
    fileprivate var botGrantable: [Element] {
        let botGrants = TokenGrant.botGrants
        
        return filter {
            botGrants.contains($0)
        }
    }
}

internal struct JWTClaim: Claims {
    let exp: Date?
    let grants: [TokenGrant]
}

typealias BarcelonaJWT = JWT<JWTClaim>

extension JWTClaim {
    func conforms(toGrants grants: [TokenGrant]) -> Bool {
        grants.allSatisfy {
            self.grants.contains($0)
        }
    }
}

extension JWT where T == JWTClaim {
    func conforms(toGrants grants: [TokenGrant]) -> Bool {
        self.claims.conforms(toGrants: grants)
    }
}

internal class JWTManager {
    internal static let sharedInstance = JWTManager()
    
    private init() {}
    
    internal func generateToken(withPSK psk: String) throws -> String {
        guard PSKManager.sharedInstance.test(key: psk) else {
            throw BarcelonaError(code: 401, message: "Invalid PSK")
        }
        
        return try generateToken(forScenario: .general, withGrants: TokenGrant.allCases)
    }
    
    internal func generateToken(fromToken authToken: BarcelonaJWT?, requestedGrants: [TokenGrant]) throws -> String {
        guard let authToken = authToken else {
            throw BarcelonaError(code: 401, message: "You must be authenticated to use this endpoint")
        }
        
        guard authToken.claims.grants.canCreateTokens else {
            throw BarcelonaError(code: 403, message: "You are not permitted to create tokens")
        }
        
        let requestedGrants = requestedGrants.botGrantable
        
        guard requestedGrants.count > 0 else {
            throw BarcelonaError(code: 400, message: "At least one grant must be provided")
        }
        
        return try generateToken(forScenario: .general, withGrants: requestedGrants)
    }
    
    internal func generateAttachmentsToken() throws -> String {
        return try generateToken(forScenario: .attachments)
    }
    
    private func generateToken(forScenario scenario: SigningScenario, withGrants grants: [TokenGrant] = []) throws -> String {
        let claims = JWTClaim(exp: scenario.expiration, grants: grants)
        
        var token = JWT(claims: claims)
        
        do {
            return try token.sign(using: try signer(forScenario: scenario))
        } catch {
            #if DEBUG
            os_log("Failed to sign token with error %{private}@", log: SecurityLog, type: .fault, error.localizedDescription)
            #endif
            
            throw BarcelonaError(code: 500, message: "Failed to sign token")
        }
    }
    
    internal func validateToken(_ token: String, forScenario scenario: SigningScenario) -> JWT<JWTClaim>? {
        do {
            let jwt = try JWT<JWTClaim>(jwtString: token, verifier: try verifier(forScenario: scenario))
            
            guard jwt.validateClaims() == .success else {
                return nil
            }
            
            return jwt
        } catch {
            #if DEBUG
            os_log("Failed to validate token with error %{private}@", log: SecurityLog, type: .fault, error.localizedDescription)
            #endif
            
            return nil
        }
    }
    
    internal func resetSigningKey() {
        self.signingKey = nil
    }
    
    private func ensureSigningKey(forScenario scenario: SigningScenario) throws -> Data {
        switch  scenario {
        case .attachments:
            if let signingKey = attachmentsSigningKey {
                return signingKey
            }
            
            let newKey = try CryptographyManager.sharedInstance.randomHash()
            
            attachmentsSigningKey = newKey
            
            return newKey
        case .general:
            if let signingKey = signingKey {
                return signingKey
            }
            
            let newKey = try CryptographyManager.sharedInstance.randomHash()
            
            signingKey = newKey
            
            return newKey
        }
    }
    
    private func signer(forScenario scenario: SigningScenario) throws -> JWTSigner {
        JWTSigner.hs256(key: try ensureSigningKey(forScenario: scenario))
    }
    
    private func verifier(forScenario scenario: SigningScenario) throws -> JWTVerifier {
        JWTVerifier.hs256(key: try ensureSigningKey(forScenario: scenario))
    }
    
    private var attachmentsSigningKey: Data? {
        get {
            SecureStorage.sharedInstance[data: attachmentsKey]
        }
        set {
            SecureStorage.sharedInstance[data: attachmentsKey] = newValue
        }
    }
    
    private var signingKey: Data? {
        get {
            SecureStorage.sharedInstance[data: jwtKey]
        }
        set {
            SecureStorage.sharedInstance[data: jwtKey] = newValue
        }
    }
}
