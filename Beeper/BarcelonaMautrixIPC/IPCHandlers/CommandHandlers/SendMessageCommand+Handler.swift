//
//  SendMessageCommand.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 8/23/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import Barcelona
import IMCore

extension SendMessageCommand: Runnable, AuthenticatedAsserting {
    public func run(payload: IPCPayload) {
        guard let chat = cbChat else {
            return payload.fail(strategy: .chat_not_found)
        }
        
        if BLUnitTests.shared.forcedConditions.contains(.messageFailure) {
            Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { _ in
                payload.fail(code: "idk", message: "couldnt send message lol")
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
                CBFeatureFlags.adHocRichLinks ? rich_link != nil : simpleRichLinkValid
            }
            
            if isRichLink {
                var threadError: Error?
                Thread.main.sync ({
                    CLDebug("BLMautrix", "I am processing a rich link! text '\(text, privacy: .private)'")
                    
                    let message = ERCreateBlankRichLinkMessage(text.trimmingCharacters(in: [" "])) { item in
                        if #available(macOS 11.0, *), let replyToGUID = reply_to {
                            item.setThreadIdentifier(IMChatItem.resolveThreadIdentifier(forMessageWithGUID: replyToGUID, part: reply_to_part ?? 0, chat: chat.imChat))
                        }
                    }
                    var afterSend: () -> () = { }
                    if CBFeatureFlags.adHocRichLinks, let richLink = rich_link {
                        do {
                            #if DEBUG
                            CLInfo("AdHocLinks", "mautrix-imessage gave me %@", try String(decoding: JSONEncoder().encode(richLink), as: UTF8.self))
                            #endif
                            afterSend = try message.provideLinkMetadata(richLink)
                        } catch {
                            threadError = error
                            return
                        }
                    } else if !CBFeatureFlags.adHocRichLinks, let url = richLinkURL, IMMessage.supportedRichLinkURL(url, additionalSupportedSchemes: []) {
                        message.loadLinkMetadata(at: url)
                    }
                    chat.imChat.send(message)
                    afterSend()
                    finalMessage = Message(ingesting: message, context: IngestionContext(chatID: chat.id))!
                } as @convention(block) () -> ())
                if let threadError = threadError {
                    throw threadError
                }
            } else {
                var messageCreation = CreateMessage(parts: [
                    .init(type: .text, details: text)
                ])
                
                messageCreation.replyToGUID = reply_to
                messageCreation.replyToPart = reply_to_part
            
                finalMessage = try chat.send(message: messageCreation)
            }
            
            payload.reply(withResponse: .message_receipt(BLPartialMessage(guid: finalMessage.id, service: finalMessage.service.rawValue, timestamp: finalMessage.time)))
        } catch {
            // girl fuck
            CLFault("BLMautrix", "failed to send text message: %@", error as NSError)
            payload.fail(code: "internal_error", message: (error as NSError).localizedFailureReason ?? error.localizedDescription)
        }
    }
}
