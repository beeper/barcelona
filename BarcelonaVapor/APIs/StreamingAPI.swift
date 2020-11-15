//
//  SocketAPI.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/5/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import CoreBarcelona
import Vapor
import os.log
import IMCore

private let log_streaming = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "StreamingAPI")

struct BootstrapData: Content, BulkChatRepresentatable {
    struct BootstrapOptions {
        var chatLimit: Int?
        var contactLimit: Int?
    }
    
    init(_ options: BootstrapOptions = BootstrapOptions(), limitChats: Int? = nil) {
        chats = IMChatRegistry.shared.allSortedChats(limit: limitChats ?? options.chatLimit)
        contacts = IMContactStore.shared.representations()
        totalChats = IMChatRegistry.shared.allChats.count
    }
    
    var chats: [Chat]
    var totalChats: Int
    var contacts: BulkContactRepresentation
    var messages: [Message]?
}

private var streamingAPI: StreamingAPI? = nil

private enum StreamCommand: Codable {
    case identify(IdentifyPayload)
    
    private enum CodingKeys: CodingKey, CaseIterable {
        case type
        case data
    }
    
    private enum CommandCodingKeys: String, CaseIterable, Codable {
        case identify
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .identify(let payload):
            try container.encode("identify", forKey: .type)
            try container.encode(payload, forKey: .data)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let type = try container.decode(CommandCodingKeys.self, forKey: .type)
        
        switch type {
        case .identify:
            let payload = try container.decode(IdentifyPayload.self, forKey: .data)
            self = .identify(payload)
        }
    }
}

private struct IdentifyPayload: Codable {
    var token: String
}

class StreamingAPI {
    static var shared: StreamingAPI {
        return streamingAPI!
    }
    
    let app: Application
    let compression: Bool
    let supervisor = DispatchSupervisor(center: NotificationCenter.default)
    let bootstrapOptions: BootstrapData.BootstrapOptions = BootstrapData.BootstrapOptions(chatLimit: nil, contactLimit: nil)
    var sockets: [WebSocket] = []
    #if BARCELONA_NO_SECURITY
    #else
    var socketAuthenticationTable: [WebSocket: Bool] = [:]
    #endif
    
    init(_ app: Application, routeBuilder: RoutesBuilder, compression: Bool = false) {
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
        
        routeBuilder.webSocket("stream") { req, socket in
            #if BARCELONA_NO_SECURITY
            self.processNewConnection(socket: socket, request: req)
            #else
            self.socketAuthenticationTable[socket] = false
            #endif
            
            socket.onText { socket, text in
                guard let data = text.data(using: .utf8), let command = try? JSONDecoder().decode(StreamCommand.self, from: data) else {
                    return
                }
                
                switch command {
                case .identify(let payload):
                    #if BARCELONA_NO_SECURITY
                    break
                    #else
                    if self.socketAuthenticationTable[socket] == true {
                        break
                    }
                    
                    guard let token = JWTManager.sharedInstance.validateToken(payload.token, forScenario: .general) else {
                        break
                    }
                    
                    if !token.conforms(toGrants: [.streaming]) {
                        socket.close(code: .policyViolation)
                        break
                    }
                    
                    self.socketAuthenticationTable[socket] = true
                    self.processNewConnection(socket: socket, request: req)
                    #endif
                }
            }
            
            socket.onClose.whenComplete { _ in
                self.offboard(socket)
            }
        }
    }
    
    private func processNewConnection(socket: WebSocket, request req: Request) {
        self.onboard(socket, chat: try? req.query.get(String.self, at: "chatPreload"), limitChats: try? req.query.get(Int.self, at: "chatLimit")).whenComplete { res in
            switch (res) {
            case .failure(let error):
                os_log("🚨 onboarding failed with error %@", type: .error, String(describing: error), log_streaming)
                break
            case .success():
                os_log("✅ onboard of socket completed", log_streaming)
                return
            }
        }
    }
    
    /**
     Called when a socket connects. Wakes up the event bus if it was asleep.
     */
    func onboard(_ socket: WebSocket, chat preload: String? = nil, limitChats: Int? = nil) -> EventLoopFuture<Void> {
        os_log("📶 Socket connected, beginning onboard", log_streaming)
        
        DispatchQueue.main.async {
            self.sockets.append(socket)
            if !self.supervisor.awake {
                self.supervisor.wake()
            }
        }
        
        var pendingMessages: EventLoopFuture<[ChatItem]>
        
        if let preload = preload, let chat = Chat.resolve(withIdentifier: preload) {
            pendingMessages = chat.messages()
        } else {
            pendingMessages = eventProcessing_eventLoop.next().makeSucceededFuture([])
        }
        
        return pendingMessages.map {
            var bootstrap = BootstrapData(self.bootstrapOptions, limitChats: limitChats)
            
            if $0.count > 0 {
                bootstrap.messages = $0.compactMap {
                    $0.messageValue
                }
            }
            
            self.dispatch(eventFor(bootstrap: bootstrap), to: [socket])
        }
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
    func dispatch<P: Codable>(_ event: Event<P>, to sockets: [WebSocket]? = nil) {
        let dispatchTracking = ERTrack(log: log_streaming, name: "Dispatching socket event", format: "Payload %@ – %d Recipients", event.type.rawValue, (sockets ?? self.sockets).count)
        
        app.eventLoopGroup.next().submit {
            let json = try JSONEncoder().encode(event)
            let sockets = sockets ?? self.sockets
            
            os_log("✉️ sending %@ payload to %d socket(s)", event.type.rawValue, sockets.count, log_streaming)
            
            if self.compression, let compressed = json.compressed {
                sockets.forEach { $0.send(raw: compressed, opcode: .binary) }
            } else {
                sockets.forEach { $0.send(raw: json, opcode: .text) }
            }
        }.whenSuccess {
            os_log("📩 finished sending %@ payload", event.type.rawValue, log_streaming)
            dispatchTracking()
        }
    }
}
