//
//  SendMediaMessageCommand+Handler.swift
//  BarcelonaFoundation
//
//  Created by Eric Rabil on 8/23/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
@_spi(messageExpertControlFlow) import Barcelona
import IMCore
import Sentry

public protocol Runnable {
    func run(payload: IPCPayload)
}

public protocol AuthenticatedAsserting {}

extension SendMediaMessageCommand: Runnable, AuthenticatedAsserting {
    public func run(payload: IPCPayload) {
        guard let chat = cbChat else {
            return payload.fail(strategy: .chat_not_found)
        }
        
        let transaction = SentrySDK.startTransaction(name: "send-message", operation: "send-media-message")
        
        let messagesDirectory = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true).appendingPathComponent("Library").appendingPathComponent("Messages")
        let messagesPath = messagesDirectory.path
        var pathOnDisk = path_on_disk
        pathOnDisk = messagesDirectory.appendingPathComponent(UUID().uuidString + "-barcelonatmp").path
        do {
            try FileManager.default.moveItem(atPath: path_on_disk, toPath: pathOnDisk)
        } catch {
            SentrySDK.capture(error: error) { scope in
                scope.span = transaction
            }
            transaction.setData(value: true, key: "fallback_to_ipc_transfer_path")
            pathOnDisk = path_on_disk
        }
        
        // if the path on disk points to the ipc path, ipc might delete. if thats the case, wait until the transfer is uploaded.
        var canSendReceiptImmediately: Bool {
            pathOnDisk != path_on_disk
        }
        
        let transfer = CBInitializeFileTransfer(filename: file_name, path: URL(fileURLWithPath: pathOnDisk))
        var messageCreation = CreateMessage(parts: [
            .init(type: .attachment, details: transfer.guid)
        ])
        
        if CBFeatureFlags.permitAudioOverMautrix {
            if is_audio_message == true {
                messageCreation.isAudioMessage = true
                transaction.setData(value: true, key: "audio_message")
            }
        }
        
        do {
            transaction.setData(value: transfer.totalBytes, key: "bytes")
            transaction.setData(value: transfer.mimeType ?? mime_type, key: "mime")
            transaction.setData(value: transfer.guid, key: "transfer_guid")
            
            var monitor: BLMediaMessageMonitor?, message: IMMessage?
            
            func resolveMessageService() -> String {
                if let message = message {
                    if let item = message._imMessageItem {
                        return item.service
                    }
                    if message.wasDowngraded {
                        return "SMS"
                    }
                }
                if chat.imChat.isDowngraded() {
                    return "SMS"
                }
                return chat.imChat.account.serviceName
            }
            
            monitor = BLMediaMessageMonitor(messageID: message?.id ?? "", transferGUIDs: [transfer.guid]) { success, failureCode, shouldCancel in
                if pathOnDisk.hasSuffix("-barcelonatmp") {
                    try? FileManager.default.removeItem(atPath: pathOnDisk)
                }
                guard let message = message else {
                    SentrySDK.capture(message: "aborting media processing because the message was never set") { scope in
                        scope.span = transaction
                    }
                    transaction.finish(status: .cancelled)
                    return
                }
                transaction.setData(value: success, key: "success")
                transaction.setData(value: failureCode?.description, key: "failure_code")
                transaction.setData(value: shouldCancel, key: "should_cancel")
                if success {
                    transaction.finish(status: .ok)
                } else {
                    transaction.finish(status: .unknownError)
                }
                if !canSendReceiptImmediately {
                    if success {
                        payload.reply(withResponse: .message_receipt(BLPartialMessage(guid: message.id, timestamp: Date().timeIntervalSinceNow)))
                    } else if let failureCode = failureCode {
                        payload.fail(code: failureCode.description, message: failureCode.localizedDescription ?? failureCode.description)
                    } else {
                        payload.fail(strategy: .internal_error("Your message was unable to be sent."))
                    }
                } else if !success && shouldCancel {
                    BLWritePayload(.init(command: .send_message_status(.init(guid: message.id, chatGUID: message._imMessageItem.service ?? chat.service?.rawValue ?? "iMessage", status: .failed, service: resolveMessageService(), message: failureCode?.localizedDescription, statusCode: failureCode?.description))))
                }
                if !success && shouldCancel {
                    chat.imChat.cancel(message)
                }
                monitor = nil
            }
            
            message = try chat.sendReturningRaw(message: messageCreation)
            
            transaction.setData(value: message?.guid, key: "message_guid")
            
            if canSendReceiptImmediately {
                payload.reply(withResponse: .message_receipt(BLPartialMessage(guid: message!.id, timestamp: Date().timeIntervalSinceNow)))
            }
        } catch {
            SentrySDK.capture(error: error) { scope in
                scope.span = transaction
            }
            transaction.finish(status: .internalError)
            CLFault("BLMautrix", "failed to send media message: %@", error as NSError)
            payload.fail(code: "internal_error", message: "Sorry, we're having trouble processing your attachment upload.")
        }
    }
}
