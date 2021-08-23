//
//  SendTapbackCommand+Handler.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 8/23/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import Barcelona

extension TapbackCommand: Runnable {
    public func run(payload: IPCPayload) {
        guard let chat = cbChat else {
            return payload.fail(strategy: .chat_not_found)
        }
        
        guard let creation = creation else {
            return payload.fail(strategy: .internal_error("Failed to create tapback operation"))
        }
        
        do {
            guard let message = try chat.tapback(creation)?.partialMessage else {
                // girl fuck
                return CLFault("BLMautrix", "failed to get sent tapback")
            }
            
            payload.respond(.message_receipt(message))
        } catch {
            // girl fuck
            CLFault("BLMautrix", "failed to send media message: %@", error as NSError)
        }
    }
}
