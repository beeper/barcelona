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

LoggingDrivers.append(BLMautrixSTDOutDriver.shared)

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

private let IPCLog = Logger(category: "MautrixIPC")

func BLHandlePayload(_ payload: IPCPayload) {
    switch payload.command {
    case .get_chats(let req):
        payload.reply(withCommand: .response(.chats_resolved(IMChatRegistry.shared.allChats.filter { chat in
            guard let lastMessage = chat.lastMessage else {
                return false
            }
            
            return lastMessage.time.timeIntervalSince1970 > req.min_timestamp
        }.map { $0.guid })))
    case .get_chat(let req):
        CLInfo("MautrixIPC", "Getting chat with id %@", req.chat_guid)
        
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
        
        BLLoadChatItems(withChatIdentifier: chat.id, onServices: .CBMessageServices, limit: req.limit).then {
            $0.blMessages
        }.then {
            payload.respond(.messages($0))
        }
    case .get_messages_after(let req):
        IPCLog("Getting messages for chat guid %@ after time %f", req.chat_guid, req.timestamp)
        
        guard let chat = req.chat else {
            IPCLog.debug("Unknown chat with guid %@", req.chat_guid)
            payload.fail(strategy: .chat_not_found)
            break
        }
        
        if let lastMessage = chat.lastMessage, lastMessage.time!.timeIntervalSince1970 < req.timestamp {
            IPCLog.debug("Not processing get_messages_after because chats last message timestamp %f is before req.timestamp %f", lastMessage.time!.timeIntervalSince1970, req.timestamp)
            return payload.respond(.messages([]))
        }
        
        IPCLog.debug("Loading %d messages in chat %@ before %f", req.limit ?? -1, chat.id, req.timestamp)
        BLLoadChatItems(withChatIdentifier: chat.id, onServices: .CBMessageServices, afterDate: req.date, limit: req.limit).then {
            $0.blMessages
        }.then {
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
        
        var messageCreation = CreateMessage(parts: [
            .init(type: .text, details: req.text)
        ])
        
        messageCreation.replyToGUID = req.reply_to
        messageCreation.replyToPart = req.reply_to_part
        
        do {
            let messages = try chat.send(message: messageCreation).map(\.partialMessage)
            BLMetricStore.shared.set(messages.map(\.guid), forKey: .lastSentMessageGUIDs)
            
            messages.forEach { message in
                payload.respond(.message_receipt(message))
            }
        } catch {
            // girl fuck
            CLFault("BLMautrix", "failed to send text message: %@", error as NSError)
        }
    case .send_media(let req):
        guard let chat = req.cbChat else {
            payload.fail(strategy: .chat_not_found)
            break
        }
        
        let transfer = CBInitializeFileTransfer(filename: req.file_name, path: URL(fileURLWithPath: req.path_on_disk)), transferGUID = transfer.guid
        let messageCreation = CreateMessage(parts: [
            .init(type: .attachment, details: transfer.guid)
        ])
        
        do {
            let messages = try chat.send(message: messageCreation).map(\.partialMessage)
            BLMetricStore.shared.set(messages.map(\.guid), forKey: .lastSentMessageGUIDs)
            
            NotificationCenter.default.subscribe(toNotificationsNamed: [.IMFileTransferUpdated, .IMFileTransferFinished]) { notif, sub in
                guard let transfer = notif.object as? IMFileTransfer, transfer.guid == transferGUID else {
                    return
                }
                
                switch transfer.state {
                case .archiving:
                    break
                case .waitingForAccept:
                    break
                case .accepted:
                    break
                case .preparing:
                    break
                case .transferring:
                    break
                case .finalizing:
                    sub.unsubscribe()
                    messages.forEach { message in
                        payload.respond(.message_receipt(message))
                    }
                case .finished:
                    break
                case .error:
                    break
                case .recoverableError:
                    break
                case .unknown:
                    break
                }
            }
        } catch {
            // girl fuck
            CLFault("BLMautrix", "failed to send media message: %@", error as NSError)
        }
    case .send_tapback(let req):
        guard let chat = req.cbChat else {
            payload.fail(strategy: .chat_not_found)
            break
        }
        
        guard let creation = req.creation else {
            payload.fail(strategy: .internal_error("Failed to create tapback operation"))
            break
        }
        
        do {
            guard let message = try chat.tapback(creation)?.partialMessage else {
                // girl fuck
                CLFault("BLMautrix", "failed to get sent tapback")
                break
            }
            
            payload.respond(.message_receipt(message))
        } catch {
            // girl fuck
            CLFault("BLMautrix", "failed to send media message: %@", error as NSError)
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

CLInfo("ERBarcelonaManager", "Bootstrapping")

BarcelonaManager.shared.bootstrap().then { success in
    guard success else {
        CLError("ERBarcelonaManager", "Failed to bootstrap")
        exit(-1)
    }
    
    ready = true
    CLInfo("ERBarcelonaManager", "BLMautrix is ready")
    NotificationCenter.default.post(name: .barcelonaReady, object: nil)
    
    BLEventHandler.shared.run()
    
    CLInfo("ERBarcelonaManager", "BLMautrix event handler is running")
}

RunLoop.main.run()
