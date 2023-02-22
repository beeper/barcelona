//
//  SendMediaMessageCommand+Handler.swift
//  BarcelonaFoundation
//
//  Created by Eric Rabil on 8/23/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Barcelona
import Foundation
import IMCore
import Logging
import Sentry

protocol Runnable {
    func run(payload: IPCPayload, ipcChannel: MautrixIPCChannel) async
}

protocol AuthenticatedAsserting {}

extension SendMediaMessageCommand: Runnable, AuthenticatedAsserting {
    var log: Logging.Logger {
        Logger(label: "SendMediaMessageCommand")
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
        let span = SentrySDK.startTransaction(name: "SendMediaMessageCommand", operation: "run", bindToScope: true)
        let breadcrumb = Breadcrumb(level: .debug, category: "command")
        breadcrumb.message = "SendMediaMessageCommand"
        breadcrumb.type = "user"
        breadcrumb.data = [
            "payload_id": String(describing: payload.id)
        ]
        SentrySDK.addBreadcrumb(breadcrumb)
        guard let chat = await cbChat, let imChat = chat.imChat else {
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

        let transfer = CBInitializeFileTransfer(filename: file_name, path: URL(fileURLWithPath: path_on_disk))
        guard let guid = transfer.guid else {
            payload.fail(
                strategy: .internal_error("created transfer was not assigned a guid!!!"),
                ipcChannel: ipcChannel
            )
            span.finish(status: .internalError)
            return
        }
        var messageCreation = CreateMessage(parts: [
            .init(type: .attachment, details: guid)
        ])
        messageCreation.metadata = metadata

        if CBFeatureFlags.permitAudioOverMautrix && is_audio_message == true {
            messageCreation.isAudioMessage = true
        }

        do {
            var monitor: BLMediaMessageMonitor?
            var message: IMMessage?

            func resolveMessageService() -> String {
                if let message = message {
                    if let item = message._imMessageItem {
                        return item.service
                    }
                    if message.wasDowngraded {
                        return "SMS"
                    }
                }
                if imChat.isDowngraded() {
                    return "SMS"
                }
                return imChat.account.serviceName
            }

            monitor = BLMediaMessageMonitor(messageID: message?.id ?? "", transferGUIDs: [guid]) {
                success,
                failureCode,
                shouldCancel in
                guard let message = message else {
                    return
                }
                if !success && shouldCancel {
                    let chatGuid = imChat.blChatGUID
                    ipcChannel.writePayload(
                        .init(
                            command: .send_message_status(
                                .init(
                                    guid: message.id,
                                    chatGUID: chatGuid,
                                    status: .failed,
                                    service: resolveMessageService(),
                                    message: failureCode?.localizedDescription,
                                    statusCode: failureCode?.description
                                )
                            )
                        )
                    )
                }
                if !success && shouldCancel {
                    imChat.cancel(message)
                }

                withExtendedLifetime(monitor) { monitor = nil }
            }

            message = try await chat.sendReturningRaw(message: messageCreation)

            payload.reply(
                withResponse: .message_receipt(
                    BLPartialMessage(
                        guid: message!.id,
                        service: resolveMessageService(),
                        timestamp: Date().timeIntervalSinceNow
                    )
                ),
                ipcChannel: ipcChannel
            )
            span.finish()
        } catch {
            SentrySDK.capture(error: error)
            log.error("failed to send media message: \(error as NSError)", source: "BLMautrix")
            payload.fail(
                code: "internal_error",
                message: "Sorry, we're having trouble processing your attachment upload.",
                ipcChannel: ipcChannel
            )
            span.finish(status: .internalError)
        }
    }
}
