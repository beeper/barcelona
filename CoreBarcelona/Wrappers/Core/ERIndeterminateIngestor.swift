//
//  ERIndeterminateIngestor.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 8/17/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import os.log
import NIO
import ObjectiveC.runtime

private let TranscriptLikeClasses = [
    IMTranscriptChatItem.self,
    IMGroupTitleChangeItem.self,
    IMParticipantChangeItem.self,
    IMGroupTitleChangeChatItem.self,
    IMGroupActionItem.self
]

private let ChatLikeClasses = [
    IMMessageActionChatItem.self,
    IMMessageActionItem.self,
    IMAttachmentMessagePartChatItem.self,
    IMTranscriptPluginChatItem.self,
    IMTextMessagePartChatItem.self,
    IMMessageAcknowledgmentChatItem.self,
    IMAssociatedMessageItem.self,
    IMAssociatedStickerChatItem.self,
    IMMessage.self,
    IMMessageItem.self
]

private let ingestor_eventLoop = MultiThreadedEventLoopGroup(numberOfThreads: 10)

private let ingestor_log = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "ERIndeterminateIngestor")

private func _ERTrackApply(_ type: OSSignpostType, log: OSLog, name: StaticString, signpostID: OSSignpostID, _ format: StaticString, _ interpolate: [CVarArg]) {
    switch interpolate.count {
    case 0:
        os_signpost(type, log: ingestor_log, name: name, signpostID: signpostID, format)
    case 1:
        os_signpost(type, log: ingestor_log, name: name, signpostID: signpostID, format, interpolate[0])
    case 2:
        os_signpost(type, log: ingestor_log, name: name, signpostID: signpostID, format, interpolate[0], interpolate[1])
    case 3:
        os_signpost(type, log: ingestor_log, name: name, signpostID: signpostID, format, interpolate[0], interpolate[1], interpolate[2])
    case 4:
        os_signpost(type, log: ingestor_log, name: name, signpostID: signpostID, format, interpolate[0], interpolate[1], interpolate[2], interpolate[3])
    default:
        os_signpost(type, log: ingestor_log, name: name, signpostID: signpostID, format, interpolate)
    }
}

public func ERTrack(log: OSLog, name: StaticString, format: StaticString, object: AnyObject = Date() as AnyObject, _ interpolate: CVarArg...) -> () -> Void {
    let signpostID = OSSignpostID.init(log: ingestor_log, object: object)
    var args = interpolate
    
    if args.count == 1, let gorked = args[0] as? [CVarArg] {
        args = gorked
    }
    
    _ERTrackApply(.begin, log: ingestor_log, name: name, signpostID: signpostID, format, args)
    
    return {
        _ERTrackApply(.end, log: ingestor_log, name: name, signpostID: signpostID, format, args)
    }
}

private func track(name: StaticString, format: StaticString, object: AnyObject = Date() as AnyObject, _ interpolate: CVarArg...) -> () -> Void {
    return ERTrack(log: ingestor_log, name: name, format: format, object: object, interpolate)
}

private let shouldLog = false

private let SPIQueue = DispatchQueue(label: "com.ericrabil.imessage-rest.SPI")

public struct ERIndeterminateIngestor {
    public static func ingest(_ object: AnyObject, in chat: String? = nil, on eventLoop: EventLoop! = nil, resolvingTapbacks: Bool = true, shouldPreprocess: Bool = true) -> EventLoopFuture<ChatItem?> {
        let eventLoop = eventLoop ?? ingestor_eventLoop.next()
        
        return preprocess(object, on: eventLoop, shouldRun: shouldPreprocess).flatMap {
            resolveLazyChatChatID(object: object, chat: chat, on: eventLoop)
        }.flatMap { chat in
            guard let chat = chat else {
                return eventLoop.makeSucceededFuture(nil)
            }
            
            let promise = eventLoop.makePromise(of: ChatItem?.self)
            
            let itemName = NSStringFromClass((object as? NSObject)?.classForCoder ?? NSNull().classForCoder)
            
            let trackerCompletion = track(name: "ingest(AnyObject)", format: "Ingesting %{public}s in chat %{public}s", itemName, chat)
            
            if shouldLog {
                os_log("Ingesting object %@ in chat %@", type: .info, itemName, chat, ingestor_log)
            }
            
            if ChatLikeClasses.contains(where: { object.isKind(of: $0) }) {
                if shouldLog {
                    os_log("Object %@ is chat-like", type: .info, itemName, ingestor_log)
                }
                
                ingest(chatLike: object, in: chat, on: eventLoop, resolvingTapbacks: resolvingTapbacks).cascade(to: promise)
            } else if TranscriptLikeClasses.contains(where: { object.isKind(of: $0) }) {
                if shouldLog {
                    os_log("Object %@ is transcript-like", type: .info, itemName, ingestor_log)
                }
                
                promise.succeed(ingest(transcriptLike: object, in: chat))
            } else {
                if shouldLog {
                    os_log("Object %@ is a stub", type: .info, itemName, ingestor_log)
                }
                
                promise.succeed(ChatItem.phantom(PhantomChatItem(object, chatID: chat)))
            }
            
            promise.futureResult.whenSuccess { _ in
                trackerCompletion()
            }
            
            return promise.futureResult
        }
    }
    
    /// Dedicated function for ingesting status items – they are not to be wrapped in Message objects as they overwrite the message data
    public static func ingest(_ status: IMMessageStatusChatItem, in chat: String? = nil, on eventLoop: EventLoop! = nil) -> EventLoopFuture<StatusChatItem?> {
        let eventLoop = eventLoop ??  ingestor_eventLoop.next()
        
        guard let messageGUID = status._item().guid else {
            return eventLoop.makeSucceededFuture(nil)
        }
        
        return IMMessage.imMessage(withGUID: messageGUID, on: eventLoop).map {
            guard let message = $0 else {
                return nil
            }
            
            return StatusChatItem(status, message: message, chatID: chat)
        }
    }
    
    public static func ingest(_ objects: [AnyObject], in chat: String? = nil, on eventLoop: EventLoop! = nil, resolvingTapbacks: Bool = true, shouldPreprocess: Bool = true) -> EventLoopFuture<[ChatItem]> {
        let eventLoop = eventLoop ??  ingestor_eventLoop.next()
        
        return preprocess(objects, on: eventLoop, shouldRun: shouldPreprocess).flatMap {
            EventLoopFuture<ChatItem?>.whenAllSucceed(objects.map {
                self.ingest($0, in: chat, on: ingestor_eventLoop.next(), resolvingTapbacks: false, shouldPreprocess: false)
            }, on: eventLoop)
        }.map {
            $0.compactMap { $0 }
        }.flatMap {
            resolvingTapbacks ? insertTapbacks(forItems: $0, in: chat, on: eventLoop) : eventLoop.makeSucceededFuture($0)
        }
    }
    
    /// Ingests an array of message-like objects and returns wrapped messages
    public static func ingest(messageLike objects: [AnyObject], in chat: String? = nil, on eventLoop: EventLoop! = nil, resolvingTapbacks: Bool = true, shouldPreprocess: Bool = true) -> EventLoopFuture<[Message]> {
        let eventLoop = eventLoop ??  ingestor_eventLoop.next()
        
        return preprocess(objects, on: eventLoop, shouldRun: shouldPreprocess).flatMap {
            EventLoopFuture<Message?>.whenAllSucceed(objects.map {
                ingest(messageLike: $0, in: chat, on: ingestor_eventLoop.next(), resolvingTapbacks: false, shouldPreprocess: false)
            }, on: eventLoop)
        }.map {
            $0.compactMap { $0 }
        }.map {
            $0.map {
                ChatItem.message($0)
            }
        }.flatMap {
            resolvingTapbacks ? insertTapbacks(forItems: $0, in: chat, on: eventLoop) : eventLoop.makeSucceededFuture($0)
        }.map {
            $0.compactMap {
                guard case .message(let message) = $0 else { return nil }
                return message
            }
        }
    }
    
    /// Ingests a message-like object and returns the wrapped message
    public static func ingest(messageLike object: AnyObject, in chat: String? = nil, on eventLoop: EventLoop! = nil, resolvingTapbacks: Bool = true, shouldPreprocess: Bool = true) -> EventLoopFuture<Message?> {
        let eventLoop = eventLoop ??  ingestor_eventLoop.next()
        
        let lazyResolution = track(name: "Chat ChatID Resolver", format: "Resolving chat ChatID. Was Provided: %{public}@", chat == nil ? "NO" : "YES")
        
        return preprocess(object, on: eventLoop, shouldRun: shouldPreprocess).flatMap {
            resolveLazyChatChatID(object: object, chat: chat, on: eventLoop)
        }.flatMap { chat in
            lazyResolution()
            
            var messageItem: IMMessageItem!, message: IMMessage!
            
            let messageFulfillment = track(name: "Message Fulfillment", format: "Fulfilling IMMessageItem/IMMessage combination from source %{public}@", String(describing: type(of: object)))
            
            switch (object) {
                case let item as IMMessageItem:
                    messageItem = item
                    message = item.message() ?? IMMessage.message(fromUnloadedItem: item)
                case let item as IMMessage:
                    message = item
                    messageItem = item._imMessageItem
                default:
                    print("Discarding unknown ChatItem \(object)")
                    return eventLoop.makeSucceededFuture(nil)
            }
            
            guard message != nil, messageItem != nil else {
                os_log("Ingestor failed to compile IMMessage/IMMessageItem combination. Provided object: %@", type: .fault, String(describing: object), ingestor_log)
                return eventLoop.makeSucceededFuture(nil)
            }
            
            messageFulfillment()
            
            var pending: EventLoopFuture<[InternalAttachment]>!
            
            let attachmentResolverTracking = track(name: "Attachment Resolution", format: "Resolving attachments for message %@", object: message, message.guid)
            
            /// sometimes IMCore wont load the missing file transfers, so we handle that using DBReader
            let missingGUIDs = messageItem.fileTransferGUIDs.filter {
                IMFileTransferCenter.sharedInstance()?.transfer(forGUID: $0) == nil
            }
            
            pending = missingGUIDs.count > 0 ? DBReader.shared.attachments(withGUIDs: missingGUIDs) : eventLoop.makeSucceededFuture([])
            
            /// After the transfers are loaded, proceed with the generation of the chat item snapshots
            return pending.map {
                $0.map {
                    $0.fileTransfer
                }
            }.flatMap { _ in
                attachmentResolverTracking()
                
                let chatItemResolverTracking = track(name: "Message Chat Item Resolution", format: "Resolving chat items for message type %{public}@ resolving tapbacks %{public}@", String(describing: type(of: object)), resolvingTapbacks ? "YES" : "NO")
                
                var parsedChatItems: EventLoopFuture<[ChatItem]>!
                
                if let chatItems = messageItem._newChatItems() {
                    parsedChatItems = ingest(chatItems, in: chat, on: eventLoop, resolvingTapbacks: resolvingTapbacks, shouldPreprocess: false)
                } else {
                    parsedChatItems = eventLoop.makeSucceededFuture([])
                }
                
                return parsedChatItems.map { chatItems in
                    
                    chatItemResolverTracking()
                    
                    let messageConstructionTracking = track(name: "Message construction", format: "Constructing message wrapper for message %@", message.guid)
                    
                    let message = Message(messageItem, message: message, items: chatItems, chatID: chat)
                    
                    messageConstructionTracking()
                    
                    return message
                }
            }
        }
    }
    
    private static func preprocess(_ object: AnyObject, on eventLoop: EventLoop, shouldRun: Bool = true) -> EventLoopFuture<Void> {
        preprocess([object], on: eventLoop, shouldRun: shouldRun)
    }
    
    private static func preprocess(_ objects: [AnyObject], on eventLoop: EventLoop, shouldRun: Bool = true) -> EventLoopFuture<Void> {
        if !shouldRun { return eventLoop.makeSucceededFuture(()) }
        
        return objects.preloadFileTransfers()
    }
    
    /// Ingests and resolves attachment metadata, succeeding with a detailed chatitem
    private static func ingest(attachment item: IMAttachmentMessagePartChatItem, in chat: String, on eventLoop: EventLoop, resolvingTapbacks: Bool = true) -> EventLoopFuture<ChatItem?> {
        var attachment: AttachmentChatItem!
        
        if let transfer = IMFileTransferCenter.sharedInstance()!.transfer(forGUID: item.transferGUID) {
            attachment = AttachmentChatItem(item, metadata: Attachment(transfer), chatID: chat)
        } else {
            attachment = AttachmentChatItem(item, chatID: chat)
        }
        
        return insertTapbacks(forChatLikeItem: attachment, on: eventLoop, resolvingTapbacks: resolvingTapbacks).map {
            .attachment($0)
        }
    }
    
    private static func insertTapbacks(forItems items: [ChatItem], in chat: String? = nil, on eventLoop: EventLoop) -> EventLoopFuture<[ChatItem]> {
        let promise = eventLoop.makePromise(of: [ChatItem].self)
        
        let tapbackTracking = ERTrack(log: ingestor_log, name: "Bulk inserting tapbacks", format: "")
        
        promise.futureResult.whenSuccess { _ in
            tapbackTracking()
        }
        
        let messageItems = items.compactMap { item -> Message? in
            guard case .message(let message) = item else { return nil }
            return message
        }
        
        var messageLedger = messageItems.reduce(into: [String: Message]()) { ledger, message in
            ledger[message.id] = message
        }
        
        let nonMessageItems = items.filter {
            switch $0 {
            case .message(_):
                return false
            default:
                return true
            }
        }
        
        let associatedLedger = messageItems.reduce(into: [String: String]()) { ledger, message in
            message.items.forEach {
                switch $0 {
                case .text(let item):
                    ledger[item.id!] = message.id
                case .attachment(let item):
                    ledger[item.id!] = message.id
                case .plugin(let item):
                    ledger[item.id!] = message.id
                default:
                    break
                }
            }
        }
        
        guard associatedLedger.count > 0 else {
            promise.succeed(items)
            return promise.futureResult
        }
        
        DBReader.shared.associatedMessages(with: Array(associatedLedger.keys), in: chat).whenSuccess { associatedMessages in
            associatedMessages.forEach { body in
                let itemGUID = body.key, messages = body.value
                guard let messageGUID = associatedLedger[itemGUID], var message = messageLedger[messageGUID] else { return }

                message.items = message.items.map { chatItem -> ChatItem in
                    switch chatItem {
                    case .text(let item):
                        return .text(assignTapbacks(forChatLikeItem: item, withID: itemGUID, tapbacks: messages))
                    case .attachment(let item):
                        return .attachment(assignTapbacks(forChatLikeItem: item, withID: itemGUID, tapbacks: messages))
                    case .plugin(let item):
                        return .plugin(assignTapbacks(forChatLikeItem: item, withID: itemGUID, tapbacks: messages))
                    default:
                        return chatItem
                    }
                }

                messageLedger[messageGUID] = message
            }

            var newItems = Array(messageLedger.values).map { ChatItem.message($0) }
            newItems.append(contentsOf: nonMessageItems)

            promise.succeed(newItems)
        }
        
        return promise.futureResult
    }
    
    private static func assignTapbacks<P: ChatItemAcknowledgable>(forChatLikeItem item: P, withID: String, tapbacks: [Message]) -> P {
        guard item.id == withID else { return item }
        var itemCopy = item
        
        itemCopy.acknowledgments = tapbacks.flatMap {
            $0.items
        }.compactMap {
            guard case .acknowledgment(let item) = $0 else { return nil }
            return item
        }
        
        return itemCopy
    }
    
    private static func insertTapbacks<P: ChatItemAcknowledgable>(forChatLikeItem item: P, on eventLoop: EventLoop, resolvingTapbacks: Bool) -> EventLoopFuture<P> {
        if !resolvingTapbacks { return eventLoop.makeSucceededFuture(item) }
        
        return item.tapbacks(on: eventLoop).map {
            var newItem = item
            newItem.acknowledgments = $0.flatMap {
                $0.items
            }.compactMap {
                guard case .acknowledgment(let item) = $0 else {
                    return nil
                }
                
                return item
            }
            return newItem
        }
    }
    
    private static func ingest(acknowledgable object: AnyObject, in chat: String, on eventLoop: EventLoop, resolvingTapbacks: Bool = true) -> EventLoopFuture<ChatItem?> {
        var pending: EventLoopFuture<ChatItem?>
        
        switch (object) {
        case let item as IMAttachmentMessagePartChatItem:
            pending = ingest(attachment: item, in: chat, on: eventLoop, resolvingTapbacks: resolvingTapbacks)
        case let item as IMTranscriptPluginChatItem:
            pending = insertTapbacks(forChatLikeItem: PluginChatItem(item, chatID: chat), on: eventLoop, resolvingTapbacks: resolvingTapbacks).map {
                .plugin($0)
            }
        case let item as IMTextMessagePartChatItem:
            pending = insertTapbacks(forChatLikeItem: TextChatItem(item, parts: ERTextParts(from: item.text), chatID: chat), on: eventLoop, resolvingTapbacks: resolvingTapbacks).map {
                .text($0)
            }
        default:
            pending = eventLoop.makeSucceededFuture(nil)
        }
        
        return pending
    }
    
    /// Process human-crafted chat items
    private static func ingest(chatLike object: AnyObject, in chat: String, on eventLoop: EventLoop, resolvingTapbacks: Bool = true) -> EventLoopFuture<ChatItem?> {
        let promise = eventLoop.makePromise(of: ChatItem?.self)
        
        switch (object) {
        case is IMAttachmentMessagePartChatItem:
            fallthrough
        case is IMTranscriptPluginChatItem:
            fallthrough
        case is IMTextMessagePartChatItem:
            self.ingest(acknowledgable: object, in: chat, on: eventLoop, resolvingTapbacks: resolvingTapbacks).cascade(to: promise)
        case let item as IMMessageAcknowledgmentChatItem:
            promise.succeed(.acknowledgment(AcknowledgmentChatItem(item, chatID: chat)))
        case let item as IMAssociatedStickerChatItem:
            promise.succeed(.sticker(StickerChatItem(item, chatID: chat)))
        case is IMAssociatedMessageItem:
            fallthrough
        case is IMMessage:
            fallthrough
        case is IMMessageItem:
            ingest(messageLike: object, in: chat, on: eventLoop, resolvingTapbacks: resolvingTapbacks, shouldPreprocess: false).map {
                guard let message = $0 else {
                    return nil
                }
                
                return .message(message)
            }.cascade(to: promise)
        default:
            promise.succeed(.phantom(PhantomChatItem(object, chatID: chat)))
        }
        
        return promise.futureResult
    }
    
    /// Processes transcript-related items and wraps them in a message item
    private static func ingest(transcriptLike object: AnyObject, in chat: String) -> ChatItem? {
        var imItem: IMItem!
        
        let itemTracking = track(name: "TranscriptItem IMItem computation", format: "Transcribing item %@", String(describing: type(of: object)))
        
        if let item = object as? IMTranscriptChatItem {
            imItem = item._item()
        } else if let item = object as? IMItem {
            imItem = item
        } else {
            return .phantom(PhantomChatItem(object, chatID: chat))
        }
        
        itemTracking()
    
        var chatItem: ChatItem? = nil
        
        let transcriptTracking = track(name: "TranscriptItem generation", format: "Transcribing item %@", String(describing: type(of: object)))
        
        switch (object) {
        case is IMDateChatItem:
            break
        case is IMSenderChatItem:
            break
        case let item as IMParticipantChangeItem:
            chatItem = .participantChange(ParticipantChangeItem(item, chatID: chat))
        case let item as IMParticipantChangeChatItem:
            chatItem = .participantChange(ParticipantChangeItem(item, chatID: chat))
        case let item as IMGroupActionItem:
            chatItem = .groupAction(GroupActionItem(item, chatID: chat))
        case let item as IMGroupActionChatItem:
            chatItem = .groupAction(GroupActionItem(item, chatID: chat))
        case let item as IMGroupTitleChangeChatItem:
            chatItem = .groupTitle(GroupTitleChangeItem(item, chatID: chat))
        case let item as IMGroupTitleChangeItem:
            chatItem = .groupTitle(GroupTitleChangeItem(item, chatID: chat))
        case let item as IMTypingChatItem:
            chatItem = .typing(TypingItem(item, chatID: chat))
            
            /// IMTypingChatItem provides its own message with populated metadata beyond what the IMItem provides
            if let message = item.message, let chatItem = chatItem {
                return .message(Message(message, items: [chatItem], chatID: chat))
            }
        default:
            break
        }
        
        var result: ChatItem
        
        if let chatItem = chatItem {
            result = .message(Message(imItem, transcriptRepresentation: chatItem, chatID: chat))
        } else {
            result = .phantom(PhantomChatItem(object, chatID: chat))
        }
        
        transcriptTracking()
        
        return result
    }
    
    private static func resolveLazyChatChatID(object: AnyObject, chat: String?, on eventLoop: EventLoop) -> EventLoopFuture<String?> {
        if let chat = chat {
            return eventLoop.makeSucceededFuture(chat)
        } else if let object = object as? IMItem, let guid = object.guid {
            return DBReader.shared.chatIdentifier(forMessageGUID: guid)
        } else if let object = object as? IMChatItem, let guid = object._item()?.guid {
            return DBReader.shared.chatIdentifier(forMessageGUID: guid)
        } else if let object = object as? IMMessage, let guid = object.guid {
            return DBReader.shared.chatIdentifier(forMessageGUID: guid)
        } else {
            return eventLoop.makeSucceededFuture(nil)
        }
    }
}
