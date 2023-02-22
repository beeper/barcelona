//
//  SendTapbackCommand+Handler.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 8/23/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Barcelona
import Foundation
import Logging

extension TapbackCommand: Runnable, AuthenticatedAsserting {
    var log: Logging.Logger {
        Logger(label: "TapbackCommand")
    }

    public func run(payload: IPCPayload, ipcChannel: MautrixIPCChannel) async {
        guard let chat = await cbChat else {
            return payload.fail(strategy: .chat_not_found, ipcChannel: ipcChannel)
        }

        guard let creation = creation else {
            return payload.fail(strategy: .internal_error("Failed to create tapback operation"), ipcChannel: ipcChannel)
        }

        do {
            await payload.respond(
                .message_receipt(try chat.tapback(creation, metadata: metadata).partialMessage),
                ipcChannel: ipcChannel
            )
        } catch {
            // girl fuck
            log.error("failed to send tapback: \(error as NSError)", source: "BLMautrix")
            payload.fail(strategy: .internal_error(error.localizedDescription), ipcChannel: ipcChannel)
        }
    }
}
