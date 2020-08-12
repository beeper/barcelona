//
//  HTTPServer.swift
//  imessage-rest
//
//  Created by Eric Rabil on 8/11/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import Vapor

/** TODO: CORS Config from a GUI */
private let corsConfiguration = CORSMiddleware.Configuration(
    allowedOrigin: .originBased,
    allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
    allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin],
    allowCredentials: true
)

/**
 Managers Vapor
 */
class ERHTTPServer {
    static let shared = ERHTTPServer()
    
    let app: Application = Application()
    let streamingAPI: StreamingAPI
    
    private init() {
        app.http.server.configuration.port = 8090;
        app.http.server.configuration.hostname = "0.0.0.0";
        
        app.middleware.use(CORSMiddleware(configuration: corsConfiguration))
        app.middleware.use(ErrorMiddleware.default(environment: app.environment))
        
        /** Socket API */
        streamingAPI = StreamingAPI(app)
        
        /** REST APIs */
        bindChatAPI(app)
        bindHandlesAPI(app)
        bindAttachmentsAPI(app)
        bindSearchAPI(app)
        bindContactsAPI(app)
        bindDebugAPI(app)
    }
    
    func start() throws {
        try app.server.start()
    }
    
    func stop() {
        app.server.shutdown()
    }
}
