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
import Swog
import BarcelonaMautrixIPCProtobuf

extension PBSendMessageRequest: Runnable, AuthenticatedAsserting {
    public func run(payload: IPCPayload) {
        guard let chat = chatGuid.chat else {
            return payload.fail(strategy: .chat_not_found)
        }
        
        if BLUnitTests.shared.forcedConditions.contains(.messageFailure) {
            Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { _ in
                payload.fail(code: "idk", message: "couldnt send message lol")
            }
            return
        }
        
        var create = CreateMessage(parts: [])
        
        if hasReplyTarget {
            create.replyToGUID = replyTarget.guid
            create.replyToPart = Int(replyTarget.part)
        }
        
        if hasMetadata {
            create.metadata = metadata.metadataValue
        }
        
        for part in parts {
            switch part.part {
            case .media:
                break
            case .text:
                break
            case .tapback:
                break
            default:
                continue
            }
        }
    }
}

extension PBMetadataValue.OneOf_Value {
    var metadataValue: MetadataValue {
        switch self {
        case .string(let string): return .string(string)
        case .bool(let bool): return .boolean(bool)
        case .double(let double): return .double(double)
        case .bytes(let bytes): return .string(bytes.base64EncodedString()) // LOSSY
        case .array(let elements): return .array(elements.values.compactMap(\.value?.metadataValue))
        case .mapping(let mapping): return .dictionary(mapping.metadataValue)
        case .int64(let int64), .sint64(let int64), .sfixed64(let int64): return .int(Int(int64))
        case .int32(let int32), .sint32(let int32), .sfixed32(let int32): return .int(Int(int32))
        case .uint64(let uint64), .fixed64(let uint64): return .int(Int(uint64))
        case .uint32(let uint32), .fixed32(let uint32): return .int(Int(uint32))
        case .float(let float): return .double(Double(float))
        }
    }
}

extension PBMapping {
    var metadataValue: [String: MetadataValue] {
        mapping.compactMapValues(\.value?.metadataValue)
    }
}

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
            
            if isRichLink, let url = rich_link?.originalURL ?? rich_link?.URL ?? richLinkURL {
                var threadError: Error?
                Thread.main.sync ({
                    CLDebug("BLMautrix", "I am processing a rich link! text '\(text, privacy: .private)'")
                    
                    let message = ERCreateBlankRichLinkMessage(text.trimmingCharacters(in: [" "]), url) { item in
                        if #available(macOS 11.0, iOS 14, *), let replyToGUID = reply_to {
                            item.setThreadIdentifier(IMChatItem.resolveThreadIdentifier(forMessageWithGUID: replyToGUID, part: reply_to_part ?? 0, chat: chat.imChat))
                        }
                    }
                    if let metadata = metadata {
                        message.metadata = metadata
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
                messageCreation.metadata = metadata
            
                finalMessage = try chat.send(message: messageCreation)
            }
            
            payload.reply(withResponse: .sendResponse(finalMessage.partialMessage))
        } catch {
            // girl fuck
            CLFault("BLMautrix", "failed to send text message: %@", error as NSError)
            switch error {
            case let error as BarcelonaError:
                payload.fail(code: error.code.description, message: error.message)
            case let error as NSError:
                payload.fail(code: error.code.description, message: error.localizedDescription)
            }
        }
    }
}
