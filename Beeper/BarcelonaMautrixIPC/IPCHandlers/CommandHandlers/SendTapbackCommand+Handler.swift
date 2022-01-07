//
//  SendTapbackCommand+Handler.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 8/23/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import Barcelona

extension TapbackCommand: Runnable, AuthenticatedAsserting {
    public func run(payload: IPCPayload) {
        guard let chat = cbChat else {
            return payload.fail(strategy: .chat_not_found)
        }
        
        guard let creation = creation else {
            return payload.fail(strategy: .internal_error("Failed to create tapback operation"))
        }
        
        do {
            payload.respond(.message_receipt(try chat.tapback(creation).partialMessage))
        } catch {
            // girl fuck
            CLFault("BLMautrix", "failed to send tapback: %@", error as NSError)
        }
    }
}
