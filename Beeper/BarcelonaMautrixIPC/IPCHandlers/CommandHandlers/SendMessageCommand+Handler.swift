//
//  SendMessageCommand.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 8/23/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import Barcelona
import IMCore

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
        do {
            var finalMessage: Message
            if !CBFeatureFlags.adHocRichLinks, let url = URL(string: text.trimmingCharacters(in: [" "])), IMMessage.supportedRichLinkURL(url, additionalSupportedSchemes: []) {
                let message = ERCreateBlankRichLinkMessage(text.trimmingCharacters(in: [" "]))
                message.loadLinkMetadata(at: url)
                finalMessage = try chat.send(message: message)
            } else {
                var messageCreation = CreateMessage(parts: [
                    .init(type: .text, details: text)
                ])
                
                messageCreation.replyToGUID = reply_to
                messageCreation.replyToPart = reply_to_part
            
            
                finalMessage = try chat.send(message: messageCreation)
            }
            payload.reply(withResponse: .message_receipt(BLPartialMessage(guid: finalMessage.id, service: finalMessage.service.rawValue, timestamp: finalMessage.time)))
        } catch {
            // girl fuck
            CLFault("BLMautrix", "failed to send text message: %@", error as NSError)
            payload.fail(code: "internal_error", message: (error as NSError).localizedFailureReason ?? error.localizedDescription)
        }
    }
}
