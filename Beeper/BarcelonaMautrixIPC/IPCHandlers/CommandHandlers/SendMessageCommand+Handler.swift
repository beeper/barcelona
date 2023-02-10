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
import Logging

private let log = Logger(label: "SendMessageCommand")

extension SendMessageCommand: Runnable, AuthenticatedAsserting {
    public func run(payload: IPCPayload, ipcChannel: MautrixIPCChannel) {
        guard let chat = cbChat, let imChat = chat.imChat else {
            return payload.fail(strategy: .chat_not_found, ipcChannel: ipcChannel)
        }
        
        if BLUnitTests.shared.forcedConditions.contains(.messageFailure) {
            Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { _ in
                payload.fail(code: "idk", message: "couldnt send message lol", ipcChannel: ipcChannel)
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
            
            if isRichLink, let url = rich_link?.originalURL ?? rich_link?.URL ?? richLinkURL {
                var threadError: Error?
                Thread.main.sync ({
                    log.debug("I am processing a rich link! text '\(text)'", source: "BLMautrix")
                    
                    let message = ERCreateBlankRichLinkMessage(text.trimmingCharacters(in: [" "]), url) { item in
                        if #available(macOS 11.0, *), let replyToGUID = reply_to {
                            item.setThreadIdentifier(IMChatItem.resolveThreadIdentifier(forMessageWithGUID: replyToGUID, part: reply_to_part ?? 0, chat: imChat))
                        }
                    }
                    if let metadata = metadata {
                        message.metadata = metadata
                    }
                    var afterSend: () -> () = { }
                    if CBFeatureFlags.adHocRichLinks, let richLink = rich_link {
                        do {
                            #if DEBUG

                            log.info("mautrix-imessage gave me \(richLink)", source: "AdHocLinks")
                            #endif
                            afterSend = try message.provideLinkMetadata(richLink)
                        } catch {
                            threadError = error
                            return
                        }
                    } else if !CBFeatureFlags.adHocRichLinks, let url = richLinkURL, IMMessage.supportedRichLinkURL(url, additionalSupportedSchemes: []) {
                        message.loadLinkMetadata(at: url)
                    }
                    imChat.send(message)
                    afterSend()
                    finalMessage = Message(ingesting: message, context: IngestionContext(chatID: chat.id, service: service))!
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
                messageCreation.metadata = metadata
            
                finalMessage = try chat.send(message: messageCreation)
            }
            
            payload.reply(withResponse: .message_receipt(BLPartialMessage(guid: finalMessage.id, service: finalMessage.service.rawValue, timestamp: finalMessage.time)), ipcChannel: ipcChannel)
        } catch {
            // girl fuck
            log.error("failed to send text message: \(error as NSError)", source: "BLMautrix")
            switch error {
            case let error as BarcelonaError:
                payload.fail(code: error.code.description, message: error.message, ipcChannel: ipcChannel)
            case let error as NSError:
                payload.fail(code: error.code.description, message: error.localizedDescription, ipcChannel: ipcChannel)
            }
        }
    }
}
