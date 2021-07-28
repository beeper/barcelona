//
//  main.swift
//  barcelona-mautrix
//
//  Created by Eric Rabil on 5/24/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import Barcelona
import BarcelonaMautrixIPC
import IMCore
import Combine

CFPreferencesSetAppValue("Log" as CFString, true as CFBoolean, kCFPreferencesCurrentApplication)
CFPreferencesSetAppValue("Log.All" as CFString, true as CFBoolean, kCFPreferencesCurrentApplication)

extension Notification.Name {
    static let barcelonaReady = Notification.Name("barcelonaReady")
}

var ready = false

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
            $0 as? Message
        }
    }
    
    var blMessages: [BLMessage] {
        var messages = messages.map(BLMessage.init(message:))
        
        messages.sort(by: <)
        
        return messages
    }
}

func BLHandlePayload(_ payload: IPCPayload) {
    BLInfo("Got a payload with type \(payload.command.name)")
    
    switch payload.command {
    case .get_chats(_):
        payload.reply(withCommand: .response(.chats_resolved(IMChatRegistry.shared.allChats.map { $0.guid })))
    case .get_chat(let req):
        BLInfo("Getting chat with id \(req.chat_guid)")
        
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
        BLInfo("Getting messages after time \(req.timestamp)")
        
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
        
        chat.send(message: messageCreation).then {
            $0.map(\.partialMessage)
        }.whenSuccess { messages in
            BLMetricStore.shared.set(messages.map(\.guid), forKey: .lastSentMessageGUIDs)
            
            messages.forEach {
                payload.respond(.message_receipt($0))
            }
        }
    case .send_media(let req):
        guard let chat = req.cbChat else {
            payload.fail(strategy: .chat_not_found)
            break
        }
        
        let transfer = CBInitializeFileTransfer(filename: req.file_name, path: URL(fileURLWithPath: req.path_on_disk))
        let messageCreation = CreateMessage(parts: [
            .init(type: .attachment, details: transfer.guid)
        ])
            
            
        chat.send(message: messageCreation).then {
            $0.map(\.partialMessage)
        }.whenSuccess { messages in
            BLMetricStore.shared.set(messages.map(\.guid), forKey: .lastSentMessageGUIDs)
            
            messages.forEach {
                payload.respond(.message_receipt($0))
            }
        }
        break
    case .send_tapback(let req):
        guard let chat = req.cbChat else {
            payload.fail(strategy: .chat_not_found)
            break
        }
        
        guard let creation = req.creation else {
            payload.fail(strategy: .internal_error("Failed to create tapback operation"))
            break
        }
        
        chat.tapback(creation).then {
            $0?.partialMessage
        }.whenComplete { result in
            switch result {
            case .success(let message):
                guard let message = message else {
                    return
                }
                
                payload.respond(.message_receipt(message))
            case .failure(let error):
                BLError("Failed to send tapback with error", error.localizedDescription)
            }
        }
    case .send_read_receipt(let req):
        guard let chat = req.chat else {
            payload.fail(strategy: .chat_not_found)
            break
        }
        
        chat.markAllMessagesAsRead()
    case .set_typing(let req):
        guard let chat = req.cbChat else {
            payload.fail(strategy: .chat_not_found)
            break
        }
        
        chat.setTyping(req.typing)
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

BarcelonaManager.shared.bootstrap().whenSuccess { success in
    guard success else {
        BLError("Failed to bootstrap")
        exit(-1)
    }
    
    ready = true
    BLInfo("BLMautrix is ready", module: "ERBarcelonaManager")
    NotificationCenter.default.post(name: .barcelonaReady, object: nil)
    
    BLEventHandler.shared.run()
    
    BLInfo("BLMautrix event handler is running", module: "ERBarcelonaManager")
}

RunLoop.main.run()
