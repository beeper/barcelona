//
//  BLHandlePayload.swift
//  BarcelonaFoundation
//
//  Created by Eric Rabil on 8/23/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import Barcelona
import IMCore
import Logging

private let log = Logger(label: "BLIPC")

private extension IPCPayload {
    var runnable: Runnable? {
        switch command {
        case .send_message(let req):
            return req
        case .send_media(let req):
            return req
        case .send_tapback(let req):
            return req
        case .send_read_receipt(let req):
            return req
        case .set_typing(let req):
            return req
        case .get_chats(let req):
            return req
        case .get_chat(let req):
            return req
        case .get_chat_avatar(let req):
            return req
        case .get_messages_after(let req):
            return req
        case .get_recent_messages(let req):
            return req
        case .resolve_identifier(let req):
            return req
        case .prepare_dm(let req):
            return req
        default:
            return nil
        }
    }
}

@MainActor
func BLHandlePayload(_ payload: IPCPayload, ipcChannel: MautrixIPCChannel) {
    guard let runnable = payload.runnable else {
        return log.warning("Received unhandleable payload type \(payload.command.name)")
    }
    
    if runnable is AuthenticatedAsserting {
        guard IMAccountController.shared.accounts.contains(where: \.canSendMessages) else {
            payload.reply(withCommand: .error(.init(code: BLHealthTicker.shared.latestStatus.state_event.rawValue, message: "You must be signed in to do that.")), ipcChannel: ipcChannel)
            return
        }
    }

    runnable.run(payload: payload, ipcChannel: ipcChannel)
}
