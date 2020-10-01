//
//  HTTPServer.swift
//  imessage-rest
//
//  Created by Eric Rabil on 8/11/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import CoreBarcelona
import BarcelonaFoundation
import Vapor

private extension ERHTTPServerConfiguration {
    private var consumableCORSOrigin: CORSMiddleware.AllowOriginSetting {
        if let allowedCorsOrigin = allowedCorsOrigin {
            return .any(allowedCorsOrigin)
        }
        
        return .originBased
    }
    
    var corsConfiguration: CORSMiddleware.Configuration {
        CORSMiddleware.Configuration(
            allowedOrigin: consumableCORSOrigin,
            allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
            allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin],
            allowCredentials: true
        )
    }
    
    func apply(toApp app: Application) {
        app.http.server.configuration.port = port
        app.http.server.configuration.hostname = hostname
        
        app.routes.defaultMaxBodySize = .init(stringLiteral: maxBodySize)
    }
}

private class ERVaporApplicationBuilder {
    fileprivate let app: Application = Application()
    
    init(configuration: ERHTTPServerConfiguration) {
        app.http.server.configuration.tlsConfiguration = SSLManager(configuration).tlsConfiguration
        
        app.middleware.use(CORSMiddleware(configuration: configuration.corsConfiguration))
        app.middleware.use(ErrorMiddleware.default(environment: app.environment))
        
        configuration.apply(toApp: app)
        
        insertBarcelonaRouting()
    }
    
    private func insertBarcelonaRouting() {
        /** Resource server so apple no kill me */
        do {
            let _ = try ERResourceServer(app)
        } catch {
            print("Failed to set up resource server with error \(error)")
        }
        
        #if BARCELONA_NO_SECURITY
        let baseRouteGroup = app.grouped([] as [Middleware])
        #else
        let baseRouteGroup = app.grouped(GeneralJWTAuthorizor().compositing([]))
        #endif
        /** Socket API */
        let _ = StreamingAPI(app, routeBuilder: baseRouteGroup, compression: false)
        
        /** REST APIs */
        bindChatAPI(baseRouteGroup)
        bindMessagesAPI(baseRouteGroup)
        bindHandlesAPI(baseRouteGroup)
        #if BARCELONA_NO_SECURITY
        bindAttachmentsAPI(baseRouteGroup, readAuthorizedBuilder: baseRouteGroup)
        #else
        bindAttachmentsAPI(baseRouteGroup, readAuthorizedBuilder: app.grouped(GeneralJWTAuthorizor().compositing(AttachmentJWTAuthorizor())))
        #endif
        bindSearchAPI(baseRouteGroup)
        bindContactsAPI(baseRouteGroup)
        bindDebugAPI(baseRouteGroup)
        
        #if BARCELONA_NO_SECURITY
        #else
        bindSecurityAPI(app, authorizedMiddleware: baseRouteGroup)
        #endif
    }
}

/**
 Managers Vapor
 */
public class ERHTTPServer {
    public static let shared = ERHTTPServer()
    
    private var app: Application?
    
    public var running: Bool {
        app != nil
    }
    
    public func start(withConfiguration configuration: ERHTTPServerConfiguration) throws {
        guard app == nil else {
            return
        }
        
        let app = ERVaporApplicationBuilder(configuration: configuration).app
        try app.start()
        self.app = app
    }
    
    public func stop() {
        guard let app = app else {
            return
        }
        
        app.server.shutdown()
        self.app = nil
    }
}
