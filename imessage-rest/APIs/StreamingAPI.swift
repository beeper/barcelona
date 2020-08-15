//
//  SocketAPI.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/5/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import Vapor
import os.log
import IMCore

private let log_streaming = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "StreamingAPI")

struct BootstrapData: Content, BulkChatRepresentatable {
    struct BootstrapOptions {
        var chatLimit: Int?
        var contactLimit: Int?
    }
    
    init(_ options: BootstrapOptions = BootstrapOptions()) {
        chats = IMChatRegistry.shared.allSortedChats(limit: options.chatLimit)
        contacts = IMContactStore.shared.representations()
    }
    
    var chats: [ChatRepresentation]
    var contacts: BulkContactRepresentation
}

private var streamingAPI: StreamingAPI? = nil

class StreamingAPI {
    static var shared: StreamingAPI {
        return streamingAPI!
    }
    
    let app: Application
    let compression: Bool
    let supervisor = DispatchSupervisor(center: NotificationCenter.default)
    let bootstrapOptions: BootstrapData.BootstrapOptions = BootstrapData.BootstrapOptions(chatLimit: 100, contactLimit: nil)
    var sockets: [WebSocket] = []
    
    init(_ app: Application, compression: Bool = false) {
        self.app = app
        self.compression = compression
        
        supervisor.register(MessageEvents.self)
        supervisor.register(ERMessageEvents.self)
        supervisor.register(ChatEvents.self)
        supervisor.register(BlocklistEvents.self)
        supervisor.register(ContactsEvents.self)
        
        if streamingAPI == nil {
            streamingAPI = self
        }
        
        app.webSocket("stream") { req, socket in
            self.onboard(socket).whenComplete { res in
                switch (res) {
                case .failure(let error):
                    os_log("🚨 onboarding failed with error %@", type: .error, String(describing: error), log_streaming)
                    break
                case .success():
                    os_log("✅ onboard of socket completed", log_streaming)
                    return
                }
            }
            
            socket.onClose.whenComplete { _ in
                self.offboard(socket)
            }
        }
    }
    
    /**
     Called when a socket connects. Wakes up the event bus if it was asleep.
     */
    func onboard(_ socket: WebSocket) -> EventLoopFuture<Void> {
        os_log("📶 Socket connected, beginning onboard", log_streaming)
        
        DispatchQueue.main.async {
            self.sockets.append(socket)
            if !self.supervisor.awake {
                self.supervisor.wake()
            }
        }
        
        return self.dispatch(eventFor(bootstrap: BootstrapData(self.bootstrapOptions)), to: [socket])
    }
    
    /**
     Called when a socket disconnects. Puts the event bus to sleep if no more sockets are connected.
     */
    func offboard(_ socket: WebSocket) {
        os_log("❌ Socket disconnected, offboarding", log_streaming)
        
        DispatchQueue.main.async {
            self.sockets.removeAll(where: { $0 == socket })
            if self.sockets.count == 0 {
                self.supervisor.sleep()
            }
        }
    }
    
    /**
     Dispatch an event packet to all sockets, or a subset of sockets is specified.
     */
    func dispatch<P: Content>(_ event: Event<P>, to sockets: [WebSocket]? = nil) -> EventLoopFuture<Void> {
        return app.eventLoopGroup.next().submit {
            let json = try JSONEncoder().encode(event)
            let sockets = sockets ?? self.sockets
            
            os_log("✉️ sending %@ payload to %d socket(s)", event.type.rawValue, sockets.count, log_streaming)
            
            if self.compression, let compressed = json.compressed {
                sockets.forEach { $0.send(raw: compressed, opcode: .binary) }
            } else {
                sockets.forEach { $0.send(raw: json, opcode: .text) }
            }
        }
    }
}
