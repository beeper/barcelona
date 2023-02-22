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
import Sentry

extension TapbackCommand: Runnable, AuthenticatedAsserting {
    var log: Logging.Logger {
        Logger(label: "TapbackCommand")
    }

    public func run(payload: IPCPayload, ipcChannel: MautrixIPCChannel) async {
        SentrySDK.configureScope { scope in
            scope.setContext(
                value: [
                    "id": String(describing: payload.id),
                    "command": payload.command.name.rawValue,
                ],
                key: "payload"
            )
        }
        let span = SentrySDK.startTransaction(name: "TapbackCommand", operation: "run", bindToScope: true)
        guard let chat = await cbChat else {
            payload.fail(strategy: .chat_not_found, ipcChannel: ipcChannel)
            span.finish(status: .notFound)
            return
        }
        SentrySDK.configureScope { scope in
            scope.setContext(
                value: [
                    "id": chat.id,
                    "service": String(describing: chat.service),
                ],
                key: "chat"
            )
        }
        let breadcrumb = Breadcrumb(level: .debug, category: "command")
        breadcrumb.message = "SendTypingCommand"
        breadcrumb.type = "user"
        breadcrumb.data = [
            "payload_id": String(describing: payload.id),
            "chat_id": chat.id,
        ]
        SentrySDK.addBreadcrumb(breadcrumb)

        guard let creation = creation else {
            payload.fail(strategy: .internal_error("Failed to create tapback operation"), ipcChannel: ipcChannel)
            span.finish(status: .internalError)
            return
        }

        do {
            payload.respond(
                .message_receipt(try await chat.tapback(creation, metadata: metadata).partialMessage),
                ipcChannel: ipcChannel
            )
            span.finish()
        } catch {
            SentrySDK.capture(error: error)
            // girl fuck
            log.error("failed to send tapback: \(error as NSError)", source: "BLMautrix")
            payload.fail(strategy: .internal_error(error.localizedDescription), ipcChannel: ipcChannel)
            span.finish(status: .internalError)
        }
    }
}
