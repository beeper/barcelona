//
//  main.swift
//  barcelona-mautrix
//
//  Created by Eric Rabil on 5/24/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import CoreBarcelona
import BarcelonaMautrixIPC
import IMCore
import Combine
import NIO

extension Notification.Name {
    static let barcelonaReady = Notification.Name("barcelonaReady")
}

var ready = false

let threadGroup = MultiThreadedEventLoopGroup(numberOfThreads: 3)

extension MultiThreadedEventLoopGroup {
    func execute(_ task: @escaping () -> ()) {
        next().execute(task)
    }
}

var BLReadyProtocols: [UUID: NSObjectProtocol] = [:]
func BLOnceReady(_ block: @escaping () -> ()) {
    let nonce = UUID()
    
    func unmount() {
        guard let proto = BLReadyProtocols[nonce] else {
            return
        }
        
        BLReadyProtocols.remove(at: BLReadyProtocols.index(forKey: nonce)!)
        NotificationCenter.default.removeObserver(proto)
    }
    
    let observer = NotificationCenter.default.addObserver(forName: .barcelonaReady, object: nil, queue: .current) { _ in
        unmount()
        block()
    }
    
    BLReadyProtocols[nonce] = observer
}

extension Array where Element == IMServiceStyle {
    static let CBMessageServices: [IMServiceStyle] = [.iMessage, .SMS]
}

extension Array where Element == ChatItem {
    var messages: [Message] {
        compactMap {
            guard case let .message(item) = $0 else {
                return nil
            }
            
            return item
        }
    }
    
    var blMessages: [BLMessage] {
        messages.map(BLMessage.init(message:))
    }
}

func BLHandlePayload(_ payload: IPCPayload) {
    BLInfo("Got a payload with type \(payload.command.name)")
    
    switch payload.command {
    case .get_chats(_):
        payload.reply(withCommand: .response(.chats_resolved(IMChatRegistry.shared.allChats.map { $0.guid })))
    case .get_chat(let req):
        guard let chat = req.blChat else {
            payload.fail(strategy: .chat_not_found)
            break
        }
        
        payload.respond(.chat_resolved(chat))
    case .get_contact(let req):
        guard let contact = req.blContact else {
            payload.fail(strategy: .contact_not_found)
            break
        }
        
        payload.respond(.contact(contact))
    case .get_recent_messages(let req):
        guard let chat = req.chat else {
            payload.fail(strategy: .chat_not_found)
            break
        }
        
        CBLoadChatItems(withChatIdentifier: chat.id, onServices: .CBMessageServices, limit: req.limit).map {
            $0.blMessages
        }.whenSuccess {
            payload.respond(.messages($0))
        }
    case .get_messages_after(let req):
        guard let chat = req.chat else {
            payload.fail(strategy: .chat_not_found)
            break
        }
        
        CBLoadChatItems(withChatIdentifier: chat.id, onServices: .CBMessageServices, beforeDate: req.date, limit: req.limit).map {
            $0.blMessages
        }.whenSuccess {
            payload.respond(.messages($0))
        }
    case .get_chat_avatar(let req):
        guard let chat = req.chat, let groupPhotoID = chat.groupPhotoID else {
            payload.respond(.chat_avatar(nil))
            break
        }
        
        payload.respond(.chat_avatar(BLAttachment(guid: groupPhotoID)))
    case .send_message(let req):
        guard let chat = req.cbChat else {
            payload.fail(strategy: .chat_not_found)
            break
        }
        
        let messageCreation = CreateMessage(parts: [
            .init(type: .text, details: req.text)
        ])
        
        chat.send(message: messageCreation).map {
            $0.messages.map {
                $0.partialMessage
            }
        }.whenSuccess {
            $0.forEach {
                payload.respond(.message_receipt($0))
            }
        }
    case .send_tapback(let req):
        guard let chat = req.cbChat else {
            payload.fail(strategy: .chat_not_found)
            break
        }
        
        
    default:
        break
    }
}

BLCreatePayloadReader { payload in
    if ready {
        BLHandlePayload(payload)
    } else {
        // defer
        BLOnceReady {
            BLHandlePayload(payload)
        }
    }
}

BLInfo("Bootstrapping", module: "ERBarcelonaManager")

ERBarcelonaManager.bootstrap { error in
    if let error = error {
        BLError("Failed to bootstrap with error %@", module: "ERBarcelonaManager", error.localizedDescription)
        exit(-1)
    }
    
    ready = true
    BLInfo("BLMautrix is ready", module: "ERBarcelonaManager")
    NotificationCenter.default.post(name: .barcelonaReady, object: nil)
}

RunLoop.current.run()
