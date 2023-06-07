//
//  SendMessageCommand.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 8/23/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Barcelona
import Foundation
import IMCore
import Logging
import Sentry

private let log = Logger(label: "SendMessageCommand")

extension SendMessageCommand: Runnable, AuthenticatedAsserting {
    func run(payload: IPCPayload, ipcChannel: MautrixIPCChannel, chatRegistry _: CBChatRegistry) async {
        SentrySDK.configureScope { scope in
            scope.setContext(
                value: [
                    "id": String(describing: payload.id),
                    "command": payload.command.name.rawValue,
                ],
                key: "payload"
            )
        }
        let span = SentrySDK.startTransaction(name: "SendMessageCommand", operation: "run", bindToScope: true)
        defer {
            span.finish()
        }
        let breadcrumb = Breadcrumb(level: .debug, category: "command")
        breadcrumb.message = "SendMessageCommand/\(payload.id ?? 0)"
        breadcrumb.type = "user"
        SentrySDK.addBreadcrumb(breadcrumb)
        guard let chat = await cbChat else {
            span.finish(status: .notFound)
            return payload.fail(strategy: .chat_not_found, ipcChannel: ipcChannel)
        }

        let imChat = chat.imChat

        SentrySDK.configureScope { scope in
            scope.setContext(
                value: [
                    "id": chat.id,
                    "service": String(describing: chat.service),
                ],
                key: "chat"
            )
        }

        if BLUnitTests.shared.forcedConditions.contains(.messageFailure) {
            Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { _ in
                payload.fail(code: "idk", message: "couldnt send message lol", ipcChannel: ipcChannel)
                span.finish(status: .aborted)
            }
            return
        }
        do {
            var finalMessage: Message!

            lazy var richLinkURL: URL? = URL(string: text.trimmingCharacters(in: [" "]))

            var simpleRichLinkValid: Bool {
                richLinkURL.map {
                    IMMessage.supportedRichLinkURL($0, additionalSupportedSchemes: [])
                } ?? false
            }

            var isRichLink: Bool {
                rich_link != nil
            }

            if isRichLink, let url = rich_link?.originalURL ?? rich_link?.URL ?? richLinkURL {
                var threadError: Error?
                Thread.main.sync(
                    {
                        span.startChild(operation: "processRichLink")
                        log.debug("I am processing a rich link! text '\(text)'", source: "BLMautrix")

                        let message = ERCreateBlankRichLinkMessage(text.trimmingCharacters(in: [" "]), url) { item in
                            if let replyToGUID = reply_to {
                                item.setThreadIdentifier(
                                    IMChatItem.resolveThreadIdentifier(
                                        forMessageWithGUID: replyToGUID,
                                        part: reply_to_part ?? 0
                                    )
                                )
                            }
                        }
                        var afterSend: () -> Void = {}
                        if let richLink = rich_link {
                            do {
                                #if DEBUG

                                log.info("mautrix-imessage gave me \(richLink)", source: "AdHocLinks")
                                #endif
                                afterSend = try message.provideLinkMetadata(richLink)
                            } catch {
                                threadError = error
                                span.finish(status: .internalError)
                                return
                            }
                        }
                        imChat.send(message)
                        afterSend()
                        finalMessage = Message(
                            ingesting: message,
                            context: IngestionContext(chatID: chat.id, service: service)
                        )!
                        span.finish()
                    } as @convention(block) () -> Void
                )
                if let threadError = threadError {
                    throw threadError
                }
            } else {
                var messageCreation = CreateMessage(parts: [
                    .init(type: .text, details: text)
                ])

                if let reply_to, !reply_to.isEmpty {
                    messageCreation.replyToGUID = reply_to
                }
                messageCreation.replyToPart = reply_to_part
                messageCreation.metadata = metadata

                finalMessage = try await chat.send(message: messageCreation)
            }

            payload.reply(
                withResponse: .message_receipt(
                    BLPartialMessage(
                        guid: finalMessage.id,
                        service: finalMessage.service.rawValue,
                        timestamp: finalMessage.time
                    )
                ),
                ipcChannel: ipcChannel
            )
            span.finish(status: .ok)
        } catch {
            SentrySDK.capture(error: error)
            // girl fuck
            log.error("failed to send text message: \(error as NSError)", source: "BLMautrix")
            switch error {
            case let error as BarcelonaError:
                payload.fail(code: error.code.description, message: error.message, ipcChannel: ipcChannel)
            case let error as NSError:
                payload.fail(code: error.code.description, message: error.localizedDescription, ipcChannel: ipcChannel)
            }
            span.finish(status: .internalError)
        }
    }
}
