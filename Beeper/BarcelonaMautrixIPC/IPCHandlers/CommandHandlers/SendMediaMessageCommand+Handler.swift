//
//  SendMediaMessageCommand+Handler.swift
//  BarcelonaFoundation
//
//  Created by Eric Rabil on 8/23/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import Barcelona
import IMCore
import Sentry

public protocol Runnable {
    func run(payload: IPCPayload, ipcChannel: MautrixIPCChannel)
}

public protocol AuthenticatedAsserting {}

extension SendMediaMessageCommand: Runnable, AuthenticatedAsserting {
    public func run(payload: IPCPayload, ipcChannel: MautrixIPCChannel) {
        guard let chat = cbChat else {
            return payload.fail(strategy: .chat_not_found, ipcChannel: ipcChannel)
        }
        
        let transaction = SentrySDK.startTransaction(name: "send-message", operation: "send-media-message")
        
        let transfer = CBInitializeFileTransfer(filename: file_name, path: URL(fileURLWithPath: path_on_disk))
        guard let guid = transfer.guid else {
            return payload.fail(strategy: .internal_error("created transfer was not assigned a guid!!!"), ipcChannel: ipcChannel)
        }
        var messageCreation = CreateMessage(parts: [
            .init(type: .attachment, details: guid)
        ])
        messageCreation.metadata = metadata
        
        if CBFeatureFlags.permitAudioOverMautrix && is_audio_message == true {
            messageCreation.isAudioMessage = true
            transaction.setData(value: true, key: "audio_message")
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
            
            monitor = BLMediaMessageMonitor(messageID: message?.id ?? "", transferGUIDs: [guid]) { success, failureCode, shouldCancel in
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
                if !success && shouldCancel {
                    ipcChannel.writePayload(.init(command: .send_message_status(.init(guid: message.id, chatGUID: chat.blChatGUID, status: .failed, service: resolveMessageService(), message: failureCode?.localizedDescription, statusCode: failureCode?.description))))
                }
                if !success && shouldCancel {
                    chat.imChat.cancel(message)
                }
                
                withExtendedLifetime(monitor) { monitor = nil }
            }
            
            message = try chat.sendReturningRaw(message: messageCreation)
            
            transaction.setData(value: message?.guid, key: "message_guid")
            
            payload.reply(withResponse: .message_receipt(BLPartialMessage(guid: message!.id, service: resolveMessageService(), timestamp: Date().timeIntervalSinceNow)), ipcChannel: ipcChannel)
        } catch {
            SentrySDK.capture(error: error) { scope in
                scope.span = transaction
            }
            transaction.finish(status: .internalError)
            CLFault("BLMautrix", "failed to send media message: %@", error as NSError)
            payload.fail(code: "internal_error", message: "Sorry, we're having trouble processing your attachment upload.", ipcChannel: ipcChannel)
        }
    }
}
