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
    
    private let app: Application = Application()
    let streamingAPI: StreamingAPI
    let resourceServer: ERResourceServer?
    
    private init() {
        app.http.server.configuration.port = 8090;
        app.http.server.configuration.hostname = "0.0.0.0";
        
        app.middleware.use(CORSMiddleware(configuration: corsConfiguration))
        app.middleware.use(ErrorMiddleware.default(environment: app.environment))
        
        /** Socket API */
        streamingAPI = StreamingAPI(app, compression: false)
        
        /** Resource server so apple no kill me */
        do {
            resourceServer = try ERResourceServer(app)
        } catch {
            resourceServer = nil
            print("Failed to set up resource server with error \(error)")
        }
        
        /** REST APIs */
        bindChatAPI(app)
        bindMessagesAPI(app)
        bindHandlesAPI(app)
        bindAttachmentsAPI(app)
        bindSearchAPI(app)
        bindContactsAPI(app)
        bindDebugAPI(app)
    }
    
    private var running: Bool = false
    
    func start() throws {
        if running {
            return
        }
        
        try app.server.start()
        running = true
    }
    
    func stop() {
        if !running {
            return
        }
        
        app.server.shutdown()
        running = false
    }
}
