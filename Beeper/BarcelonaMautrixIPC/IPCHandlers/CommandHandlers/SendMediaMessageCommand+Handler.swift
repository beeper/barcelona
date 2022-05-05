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

public protocol Runnable {
    func run(payload: IPCPayload)
}

public protocol AuthenticatedAsserting {}

extension SendMediaMessageCommand: Runnable, AuthenticatedAsserting {
    public func run(payload: IPCPayload) {
        guard let chat = cbChat else {
            return payload.fail(strategy: .chat_not_found)
        }
        let messagesDirectory = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true).appendingPathComponent("Library").appendingPathComponent("Messages")
        let messagesPath = messagesDirectory.path
        var pathOnDisk = path_on_disk
        pathOnDisk = messagesDirectory.appendingPathComponent(UUID().uuidString + "-barcelonatmp").path
        do {
            try FileManager.default.moveItem(atPath: path_on_disk, toPath: pathOnDisk)
        } catch {
            pathOnDisk = path_on_disk
        }
        
        let transfer = CBInitializeFileTransfer(filename: file_name, path: URL(fileURLWithPath: pathOnDisk))
        var messageCreation = CreateMessage(parts: [
            .init(type: .attachment, details: transfer.guid)
        ])
        
        if CBFeatureFlags.permitAudioOverMautrix {
            if is_audio_message == true {
                messageCreation.isAudioMessage = true
            }
        }
        
        do {
            var monitor: BLMediaMessageMonitor?, message: IMMessage?
            monitor = BLMediaMessageMonitor(messageID: message?.id ?? "", transferGUIDs: [transfer.guid]) { success, failureCode, shouldCancel in
                if pathOnDisk.hasSuffix("-barcelonatmp") {
                    try? FileManager.default.removeItem(atPath: pathOnDisk)
                }
                guard let message = message else {
                    return
                }
                if success {
                    payload.reply(withResponse: .message_receipt(BLPartialMessage(guid: message.id, timestamp: Date().timeIntervalSinceNow)))
                } else {
                    if let failureCode = failureCode {
                        payload.fail(code: failureCode.description, message: failureCode.localizedDescription ?? failureCode.description)
                    } else {
                        payload.fail(strategy: .internal_error("Your message was unable to be sent."))
                    }
                    if shouldCancel {
                        chat.imChat.cancel(message)
                    }
                }
                monitor = nil
            }
            
            message = try chat.sendReturningRaw(message: messageCreation)
        } catch {
            CLFault("BLMautrix", "failed to send media message: %@", error as NSError)
            payload.fail(code: "internal_error", message: "Sorry, we're having trouble processing your attachment upload.")
        }
    }
}
