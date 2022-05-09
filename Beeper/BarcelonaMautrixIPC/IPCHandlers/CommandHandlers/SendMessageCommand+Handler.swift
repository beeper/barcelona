//
//  SendMessageCommand.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 8/23/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import Barcelona

extension SendMessageCommand: Runnable, AuthenticatedAsserting {
    public func run(payload: IPCPayload) {
        guard let chat = cbChat else {
            return payload.fail(strategy: .chat_not_found)
        }
        
        if BLUnitTests.shared.forcedConditions.contains(.messageFailure) {
            Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { _ in
                payload.fail(code: "idk", message: "couldnt send message lol")
            }
            return
        }
        
        var messageCreation = CreateMessage(parts: [
            .init(type: .text, details: text)
        ])
        
        messageCreation.replyToGUID = reply_to
        messageCreation.replyToPart = reply_to_part
        
        do {
            let message = try chat.send(message: messageCreation)
            payload.reply(withResponse: .message_receipt(BLPartialMessage(guid: message.id, timestamp: message.time)))
        } catch {
            // girl fuck
            CLFault("BLMautrix", "failed to send text message: %@", error as NSError)
            payload.fail(code: "internal_error", message: (error as NSError).localizedFailureReason ?? error.localizedDescription)
        }
    }
}
