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
import IMFoundation
import Logging
import Sentry

protocol Runnable {
    func run(payload: IPCPayload, ipcChannel: MautrixIPCChannel) async
}

public extension SentrySDK {
    static func startIPCTransaction(
        forPayload payload: IPCPayload,
        uppercasedName: String
    ) -> Sentry.Span {
        SentrySDK.configureScope { scope in
            scope.setContext(
                value: [
                    "id": String(describing: payload.id),
                    "command": payload.command.name.rawValue
                ],
                key: "payload"
            )
        }

        let span = SentrySDK.startTransaction(name: uppercasedName, operation: "run", bindToScope: true)
        let breadcrumb = Breadcrumb(level: .debug, category: "command")
        breadcrumb.message = "\(uppercasedName)/\(payload.id ?? 0)"
        breadcrumb.type = "user"
        SentrySDK.addBreadcrumb(breadcrumb)

        return span
    }
}

protocol AuthenticatedAsserting {}

extension SendMediaMessageCommand: Runnable, AuthenticatedAsserting {
    var log: Logging.Logger {
        Logger(label: "SendMediaMessageCommand")
    }

    func uploadAndRetry(filename: String, path: String) async throws -> String {
        let uploader = MediaUploader()
        for attempt in 1..<3 {
            log.debug("Upload file attempt \(attempt)")
            do {
                log.debug("Uploading")
                let guid = try await uploader.uploadFile(filename: filename, path: URL(fileURLWithPath: path))
                log.debug("Uploaded file with transfer guid \(guid)")
                return guid
            } catch {
                log.debug("Upload attempt \(attempt) failed: \(error.localizedDescription). Retrying in \(attempt)s")
                try await Task.sleep(nanoseconds: UInt64(attempt) * 1_000_000_000)
                continue
            }
        }
        log.debug("Trying to upload the file one last time")
        let guid = try await uploader.uploadFile(filename: filename, path: URL(fileURLWithPath: path))
        log.debug("Final upload attempt succeeded with guid: \(guid)")
        return guid
    }

    func run(payload: IPCPayload, ipcChannel: MautrixIPCChannel) async {
        let span = SentrySDK.startIPCTransaction(forPayload: payload, uppercasedName: "SendMediaMessageCommand")

        guard let chat = await cbChat else {
            payload.fail(strategy: .chat_not_found, ipcChannel: ipcChannel)
            span.finish(status: .notFound)
            return
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

        do {
            var send_file_name = file_name
            var send_path = path_on_disk
            let correct_name = "Audio Message.caf"
            if is_audio_message == true && file_name != correct_name {
                send_path = send_path.replacingOccurrences(of: file_name, with: correct_name)
                send_file_name = correct_name
                try FileManager.default.moveItem(atPath: path_on_disk, toPath: send_path)
            }

            log.debug("Starting attachment upload")
            let guid = try await uploadAndRetry(filename: send_file_name, path: send_path)
            log.debug("Attachment upload finished with GUID: \(guid)")

            var parts: [MessagePart] = [
                .init(type: .attachment, details: guid),
            ]

            if let text, !text.isEmpty {
                parts.append(.init(type: .text, details: text))
            }

            var messageCreation = CreateMessage(parts: parts)
            messageCreation.metadata = metadata
            messageCreation.isAudioMessage = is_audio_message

            log.debug("Sending message with transfer \(guid)")
            let message = await chat.sendReturningRaw(message: messageCreation)
            log.debug("Message sent, got: \(message)")

            let service: String = {
                if let item = message._imMessageItem {
                    return item.service
                }
                if message.wasDowngraded {
                    return "SMS"
                }
                if imChat.isDowngraded() {
                    return "SMS"
                }
                return imChat.account.serviceName
            }()

            log.debug("Responding to payload with message_receipt")
            payload.reply(
                withResponse: .message_receipt(
                    BLPartialMessage(
                        guid: message.id,
                        service: service,
                        timestamp: Date().timeIntervalSinceNow
                    )
                ),
                ipcChannel: ipcChannel
            )
            span.finish(status: .ok)
        } catch let error as LocalizedError & CustomNSError {
            SentrySDK.capture(error: error)
            let userError = FZErrorType.attachmentUploadFailure
            log.error("failed to send media message: \(error) replying to user with: \(userError.description)")
            payload.fail(
                code: userError.description,
                message: userError.localizedDescription ?? "Unkown error",
                ipcChannel: ipcChannel
            )
            span.finish(status: .internalError)
        } catch {
            SentrySDK.capture(error: error)
            log.error("failed to send media message: \(error)")
            payload.fail(
                code: "internal_error",
                message: "Sorry, we're having trouble processing your attachment upload.",
                ipcChannel: ipcChannel
            )
            span.finish(status: .internalError)
        }
    }
}
