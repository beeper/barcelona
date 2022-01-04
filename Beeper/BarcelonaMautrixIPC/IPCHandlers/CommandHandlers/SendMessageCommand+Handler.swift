//
//  SendMessageCommand.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 8/23/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import Barcelona

extension SendMessageCommand: Runnable {
    public internal(set) static var pendingPayloads: [String: IPCPayload] = [:]
    
    public static func messageSent(withGUID guid: String) -> IPCPayload? {
        return pendingPayloads.removeValue(forKey: guid)
    }
    
    public func run(payload: IPCPayload) {
        guard let chat = cbChat else {
            return payload.fail(strategy: .chat_not_found)
        }
        
        var messageCreation = CreateMessage(parts: [
            .init(type: .text, details: text)
        ])
        
        messageCreation.replyToGUID = reply_to
        messageCreation.replyToPart = reply_to_part
        
        do {
            let message = try chat.send(message: messageCreation)
            Self.pendingPayloads[message.id] = payload
        } catch {
            // girl fuck
            CLFault("BLMautrix", "failed to send text message: %@", error as NSError)
        }
    }
}
