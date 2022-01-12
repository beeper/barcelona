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

public protocol Runnable {
    func run(payload: IPCPayload)
}

public protocol AuthenticatedAsserting {}

extension SendMediaMessageCommand: Runnable, AuthenticatedAsserting {
    public func run(payload: IPCPayload) {
        guard let chat = cbChat else {
            return payload.fail(strategy: .chat_not_found)
        }
        
        let transfer = CBInitializeFileTransfer(filename: file_name, path: URL(fileURLWithPath: path_on_disk)), transferGUID = transfer.guid
        var messageCreation = CreateMessage(parts: [
            .init(type: .attachment, details: transfer.guid)
        ])
        
        if CBFeatureFlags.permitAudioOverMautrix {
            if is_audio_message == true {
                messageCreation.isAudioMessage = true
            }
            
            if !CBFeatureFlags.permitInvalidAudioMessages {
                // validate mime type blah
            }
        }
        
        do {
            let message = try chat.send(message: messageCreation).partialMessage
            SendMessageCommand.suppressedGUIDs.insert(message.guid)
            
            NotificationCenter.default.subscribe(toNotificationsNamed: [.IMFileTransferUpdated, .IMFileTransferFinished]) { notif, sub in
                guard let transfer = notif.object as? IMFileTransfer, transfer.guid == transferGUID else {
                    return
                }
                
                switch transfer.state {
                case .archiving:
                    break
                case .waitingForAccept:
                    break
                case .accepted:
                    break
                case .preparing:
                    break
                case .transferring:
                    break
                case .finalizing:
                    fallthrough
                case .finished:
                    sub.unsubscribe()
                    payload.respond(.message_receipt(message))
                case .error:
                    break
                case .recoverableError:
                    break
                case .unknown:
                    break
                }
            }
        } catch {
            CLFault("BLMautrix", "failed to send media message: %@", error as NSError)
            payload.reply(withCommand: .error(.init(code: "internal_error", message: "Sorry, we're having trouble processing your attachment upload.")))
        }
    }
}
