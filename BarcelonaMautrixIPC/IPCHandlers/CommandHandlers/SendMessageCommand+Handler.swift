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
            let messages = try chat.send(message: messageCreation).map(\.partialMessage)
            BLMetricStore.shared.set(messages.map(\.guid), forKey: .lastSentMessageGUIDs)
            
            messages.forEach { message in
                payload.respond(.message_receipt(message))
            }
        } catch {
            // girl fuck
            CLFault("BLMautrix", "failed to send text message: %@", error as NSError)
        }
    }
}
