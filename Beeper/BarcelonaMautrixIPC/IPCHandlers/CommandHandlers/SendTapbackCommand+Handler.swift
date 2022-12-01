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
    public func run(payload: IPCPayload, ipcChannel: MautrixIPCChannel) {
        guard let chat = cbChat else {
            return payload.fail(strategy: .chat_not_found, ipcChannel: ipcChannel)
        }
        
        guard let creation = creation else {
            return payload.fail(strategy: .internal_error("Failed to create tapback operation"), ipcChannel: ipcChannel)
        }
        
        do {
            payload.respond(.message_receipt(try chat.tapback(creation, metadata: metadata).partialMessage), ipcChannel: ipcChannel)
        } catch {
            // girl fuck
            CLFault("BLMautrix", "failed to send tapback: %@", error as NSError)
        }
    }
}
