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

private let log_streaming = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "StreamingAPI")

struct Event<P: Content>: Content {
    public let type: Event.EventType
    public let data: P?
    
    enum EventType: String, Content {
        case bootstrap
        case itemsReceived
        case itemsRemoved
        case participantsChanged
        case conversationRemoved
        case conversationCreated
        case conversationChanged
        case conversationDisplayNameChanged
        case conversationJoinStateChanged
        case contactCreated
        case contactRemoved
        case contactUpdated
        case blockListUpdated
    }
}

func eventFor(bootstrap: BootstrapData) -> Event<BootstrapData> {
    return Event<BootstrapData>(type: .bootstrap, data: bootstrap)
}

func eventFor(itemsReceived: BulkChatItemRepresentation) -> Event<BulkChatItemRepresentation> {
    return Event<BulkChatItemRepresentation>(type: .itemsReceived, data: itemsReceived)
}

func eventFor(itemsRemoved: BulkMessageIDRepresentation) -> Event<BulkMessageIDRepresentation> {
    return Event<BulkMessageIDRepresentation>(type: .itemsRemoved, data: itemsRemoved)
}

struct ParticipantChangeRecord: Content, BulkHandleIDRepresentable {
    var chat: String
    var handles: [String]
}

func eventFor(participantsChanged: [String], in chat: String) -> Event<ParticipantChangeRecord> {
    return Event<ParticipantChangeRecord>(type: .participantsChanged, data: ParticipantChangeRecord(chat: chat, handles: participantsChanged))
}

func eventFor(conversationRemoved: ChatIDRepresentation) -> Event<ChatIDRepresentation> {
    return Event<ChatIDRepresentation>(type: .conversationRemoved, data: conversationRemoved)
}

func eventFor(conversationCreated: ChatRepresentation) -> Event<ChatRepresentation> {
    return Event<ChatRepresentation>(type: .conversationCreated, data: conversationCreated)
}

func eventFor(conversationChanged: ChatRepresentation) -> Event<ChatRepresentation> {
    return Event<ChatRepresentation>(type: .conversationChanged, data: conversationChanged)
}

func eventFor(conversationDisplayNameChanged: ChatRepresentation) -> Event<ChatRepresentation> {
    return Event<ChatRepresentation>(type: .conversationDisplayNameChanged, data: conversationDisplayNameChanged)
}

func eventFor(conversationJoinStateChanged: ChatRepresentation) -> Event<ChatRepresentation> {
    return Event<ChatRepresentation>(type: .conversationJoinStateChanged, data: conversationJoinStateChanged)
}

func eventFor(contactCreated: ContactRepresentation) -> Event<ContactRepresentation> {
    return Event<ContactRepresentation>(type: .contactCreated, data: contactCreated)
}

func eventFor(contactRemoved: ContactIDRepresentation) -> Event<ContactIDRepresentation> {
    return Event<ContactIDRepresentation>(type: .contactRemoved, data: contactRemoved)
}

func eventFor(contactUpdated: ContactRepresentation) -> Event<ContactRepresentation> {
    return Event<ContactRepresentation>(type: .contactUpdated, data: contactUpdated)
}

func eventFor(blockListUpdated: BulkHandleIDRepresentation) -> Event<BulkHandleIDRepresentation> {
    return Event<BulkHandleIDRepresentation>(type: .blockListUpdated, data: blockListUpdated)
}

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
    
    func offboard(_ socket: WebSocket) {
        os_log("❌ Socket disconnected, offboarding", log_streaming)
        
        DispatchQueue.main.async {
            self.sockets.removeAll(where: { $0 == socket })
            if self.sockets.count == 0 {
                self.supervisor.sleep()
            }
        }
    }
    
    func dispatch<P: Content>(_ event: Event<P>, to sockets: [WebSocket]?) -> EventLoopFuture<Void> {
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
