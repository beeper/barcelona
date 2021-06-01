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

func BLHandlePayload(_ payload: IPCPayload) {
    BLInfo("Got a payload with type \(payload.command.name)")
    
    switch payload.command {
    case .get_chats(_):
        payload.reply(withCommand: .response(.chats_resolved(IMChatRegistry.shared.allChats.map { $0.guid })))
        break
    case .get_chat(let req):
        if let chat = req.chat?.blChat {
            payload.reply(withCommand: .response(.chat_resolved(chat)))
        }
    case .get_contact(let req):
        BLInfo("Contact ID: %@", req.user_guid)
        if let contact = req.blContact {
            payload.reply(withCommand: .response(.contact(contact)))
        }
    case .get_recent_messages(let req):
        guard let chat = req.chat else {
            break
        }
        
        threadGroup.execute {
            Chat(chat).messages(before: nil, limit: req.limit).whenSuccess { items in
                payload.respond(.messages(items.compactMap {
                    $0.messageValue
                }.map {
                    BLMessage(message: $0)
                }))
            }
        }
    case .get_chat_avatar(let req):
        guard let chat = req.chat, let groupPhotoID = chat.groupPhotoID else {
            payload.respond(.chat_avatar(nil))
            break
        }
        
        payload.respond(.chat_avatar(BLAttachment(guid: groupPhotoID)))
        break
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
