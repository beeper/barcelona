//
//  SecurityAPI.swift
//  BarcelonaVapor
//
//  Created by Eric Rabil on 9/22/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import CoreBarcelona
import Vapor

public struct TokenRequest: Content {
    var psk: String
}

public struct BotTokenRequest: Content {
    var grants: [TokenGrant]
}

public struct TokenResponse: Content {
    var token: String
}

public struct PSKRequest: Content {
    var oldPSK: String?
    var newPSK: String
}

private extension JWTManager {
    func generateTokenResponse(withPSK psk: String) throws -> TokenResponse {
        let token = try generateToken(withPSK: psk)
        
        return TokenResponse(token: token)
    }
    
    func generateTokenResponse(fromToken token: BarcelonaJWT?, withGrants grants: [TokenGrant]) throws -> TokenResponse {
        let token = try generateToken(fromToken: token, requestedGrants: grants)
        
        return TokenResponse(token: token)
    }
}

public func bindSecurityAPI(_ app: Application, authorizedMiddleware: RoutesBuilder) {
    #if BARCELONA_NO_SECURITY
    #else
    let security = app.grouped("security")
    let authorizedSecurity = authorizedMiddleware.grouped("security")
    
    security.patch("psk") { req -> TokenResponse in
        guard let pskRequest = try? req.content.decode(PSKRequest.self) else {
            throw BarcelonaError(code: 400, message: "Invalid PSK request")
        }
        
        try PSKManager.sharedInstance.reset(oldKey: pskRequest.oldPSK, token: req.headers.first(name: .authorization), newKey: pskRequest.newPSK)
        
        return try JWTManager.sharedInstance.generateTokenResponse(withPSK: pskRequest.newPSK)
    }

    security.post("token") { req -> TokenResponse in
        guard let tokenRequest = try? req.content.decode(TokenRequest.self) else {
            throw BarcelonaError(code: 400, message: "Invalid token request")
        }
        
        return try JWTManager.sharedInstance.generateTokenResponse(withPSK: tokenRequest.psk)
    }
    
    authorizedSecurity.post("bot-token") { req -> TokenResponse in
        guard let botTokenRequest = try? req.content.decode(BotTokenRequest.self) else {
            throw BarcelonaError(code: 400, message: "Invalid token request")
        }
        
        return try JWTManager.sharedInstance.generateTokenResponse(fromToken: req.token, withGrants: botTokenRequest.grants)
    }
    
    authorizedSecurity.get("attachment-session") { req -> Response in
        let attachmentsToken = try JWTManager.sharedInstance.generateAttachmentsToken()
        
        var headers = HTTPHeaders()
        
        headers.setCookie = .init(dictionaryLiteral: (AttachmentsCookieName, .init(string: attachmentsToken, maxAge: Int(ATTACHMENTS_EXPIRATION_SECONDS))))
        
        return .init(status: .noContent, headers: headers)
    }
    #endif
}
