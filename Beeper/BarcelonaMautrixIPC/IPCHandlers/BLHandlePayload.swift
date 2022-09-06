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
import Swog

internal let IPCLog = Logger(category: "BLIPC")

private extension IPCPayload {
    var runnable: Runnable? {
        switch command {
        case .sendMessage(let req):
            return req
//        case .send_media(let req):
//            return req
//        case .send_tapback(let req):
//            return req
        case .sendReadReceipt(let req):
            return req
        case .setTyping(let req):
            return req
        case .getChats(let req):
            return req
        case .getChat(let req):
            return req
        case .getChatAvatar(let req):
            return req
        case .getContact(let req):
            return req
        case .getMessagesAfter(let req):
            return req
        case .getRecentMessages(let req):
            return req
        case .getContactList(let req):
            return PBContactList.Runner()
        case .resolveIdentifier(let req):
            return req
        case .prepareDm(let req):
            return req
        case .historyQuery(let req):
            return req
        default:
            return nil
        }
    }
}

import BarcelonaMautrixIPCProtobuf

extension PBPayload {
    func reply(_ command: PBPayload.OneOf_Command) {
        BLWritePayload {
            $0.id = self.id
            $0.isResponse = true
            $0.command = command
        }
    }
}

public func BLHandlePayload(_ payload: PBPayload) {
    if let runnable = payload.runnable {
        runnable.run(payload: payload)
    } else {
        switch payload.command {
        case .preStartupSync:
            payload.reply(.syncHookResponse(.with {
                $0.skipSync = false
            }))
            return
        case .ping:
            payload.reply(.pong(.init()))
            return
        default:
            break
        }
        CLWarn("BLSTDIO", "Dropping unhandleable payload %@", payload.debugDescription)
    }
}
