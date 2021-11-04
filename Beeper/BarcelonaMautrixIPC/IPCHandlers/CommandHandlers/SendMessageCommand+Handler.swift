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
    public internal(set) static var suppressedGUIDs: Set<String> = Set()
    
    public enum MessageHandlingBehavior {
        case process, suppress
    }
    
    public static func messageSent(withGUID guid: String) -> MessageHandlingBehavior {
        if suppressedGUIDs.remove(guid) != nil {
            return .suppress
        } else {
            return .process
        }
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
            let message = try chat.send(message: messageCreation).partialMessage
            Self.suppressedGUIDs.insert(message.guid)
            
            payload.respond(.message_receipt(message))
        } catch {
            // girl fuck
            CLFault("BLMautrix", "failed to send text message: %@", error as NSError)
        }
    }
}
