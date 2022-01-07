//
//  Message.swift
//  imcore-rest
//
//  Created by Eric Rabil on 7/24/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import IMSharedUtilities
import BarcelonaDB
import Swog

public extension Array where Element == String {
    func er_chatItems(in chat: String) -> Promise<[ChatItem]> {
        IMMessage.messages(withGUIDs: self)
    }
}

private func CBExtractThreadOriginatorAndPartFromIdentifier(_ identifier: String) -> (String, Int)? {
    let parts = identifier.split(separator: ",")
    
    if #available(macOS 10.16, iOS 14.0, *), let identifierData = CBMessageItemIdentifierData(rawValue: IMMessageCreateAssociatedMessageGUIDFromThreadIdentifier(identifier)) {
        guard let part = identifierData.part else {
            return nil
        }
        
        return (identifierData.id, part)
    }
    
    guard parts.count > 2 else {
        return nil
    }
    
    guard let part = Int(parts[1]), let identifier = parts.last else {
        return nil
    }
    
    return (String(identifier), part)
}

private extension IngestionContext {
    func ingest(_ items: [NSObject]) -> [ChatItem] {
        CLDebug("IngestionContext", "Ingesting items: \(items, privacy: .private)")
        
        return items.map {
            ChatItemType.ingest(object: $0, context: self)
        }
    }
}

private extension IngestionContext {
    func items(forMessageItem item: IMMessageItem) -> [ChatItem] {
        ingest(item.chatItems)
    }
    
    func items(forMessage message: IMMessage) -> [ChatItem] {
        ingest(message._imMessageItem?.chatItems ?? [])
    }
}

extension FZErrorType: Codable {
    public init(from decoder: Decoder) throws {
        self = .init(rawValue: try decoder.singleValueContainer().decode(RawValue.self)) ?? .unknownError
    }
    
    public func encode(to encoder: Encoder) throws {
        try rawValue.encode(to: encoder)
    }
}

extension FZErrorType: CustomStringConvertible {
    public var localizedDescription: String {
        switch self {
        case .noError:
            return ""
        case .unknownError, .cancelled, .timeout, .sendFailed, .internalFailure, .textRenderingPreflightFailed:
            return "An unknown error \(rawValue)/\(description)) was encountered while sending your message."
        case .networkFailure, .networkLookupFailure, .networkConnectionFailure, .noNetworkFailure, .networkBusyFailure, .networkDeniedFailure:
            return "An internal network error is preventing your message from being sent."
        case .serverSignatureError, .serverDecodeError, .serverParseError, .serverInternalError, .serverInvalidRequestError, .serverMalformedRequestError, .serverUnknownRequestError, .serverInvalidTokenError, .serverRejectedError:
            return "An error was encountered while communicating with the server."
        case .remoteUserInvalid, .remoteUserDoesNotExist, .remoteUserIncompatible, .remoteUserRejected:
            return "The person you are trying to message is unavailable or does not exist."
        case .transcodingFailure:
            return "An error was encountered while transcoding your message."
        case .encryptionFailure, .otrEncryptionFailure:
            return "There's an issue with your iMessage encryption that is preventing messages from being sent."
        case .decryptionFailure, .otrDecryptionFailure:
            return "There's an issue with your iMessage decryption that is preventing messages from being processed."
        case .localAccountDisabled:
            return "You cannot use this service at this time."
        case .localAccountDoesNotExist:
            return "This service is not set up."
        case .localAccountInvalid, .localAccountNeedsUpdate:
            return "This account is misconfigured and you cannot send messages at this time."
        case .attachmentUploadFailure, .messageAttachmentUploadFailure:
            return "Sorry, we're having trouble uploading your attachment."
        case .attachmentDownloadFailure, .messageAttachmentDownloadFailure:
            return "Sorry, we couldn't download that attachment."
        case .systemNeedsUpdate:
            return "Please update the system running iMessage."
        case .serviceCrashed:
            return "A temporary outage stopped your message from being sent. Please try again."
        case .invalidLocalCredentials:
            return "You've been signed out of iMessage. Please log back in."
        case .attachmentDownloadFailureFileNotFound:
            return "One or more attachments associated with this message are no longer available to download."
        @unknown default:
            return "An unknown error (\(rawValue)) was encountered while sending your message."
        }
    }
    
    public var description: String {
        switch self {
        case .noError:
            return "noError"
        case .unknownError:
            return "unknownError"
        case .cancelled:
            return "cancelled"
        case .timeout:
            return "timeout"
        case .sendFailed:
            return "sendFailed"
        case .internalFailure:
            return "internalFailure"
        case .networkFailure:
            return "networkFailure"
        case .networkLookupFailure:
            return "networkLookupFailure"
        case .networkConnectionFailure:
            return "networkConnectionFailure"
        case .noNetworkFailure:
            return "noNetworkFailure"
        case .networkBusyFailure:
            return "networkBusyFailure"
        case .networkDeniedFailure:
            return "networkDeniedFailure"
        case .serverSignatureError:
            return "serverSignatureError"
        case .serverDecodeError:
            return "serverDecodeError"
        case .serverParseError:
            return "serverParseError"
        case .serverInternalError:
            return "serverInternalError"
        case .serverInvalidRequestError:
            return "serverInvalidRequestError"
        case .serverMalformedRequestError:
            return "serverMalformedRequestError"
        case .serverUnknownRequestError:
            return "serverUnknownRequestError"
        case .serverInvalidTokenError:
            return "serverInvalidTokenError"
        case .serverRejectedError:
            return "serverRejectedError"
        case .remoteUserInvalid:
            return "remoteUserInvalid"
        case .remoteUserDoesNotExist:
            return "remoteUserDoesNotExist"
        case .remoteUserIncompatible:
            return "remoteUserIncompatible"
        case .remoteUserRejected:
            return "remoteUserRejected"
        case .transcodingFailure:
            return "transcodingFailure"
        case .encryptionFailure:
            return "encryptionFailure"
        case .decryptionFailure:
            return "decryptionFailure"
        case .otrEncryptionFailure:
            return "otrEncryptionFailure"
        case .otrDecryptionFailure:
            return "otrDecryptionFailure"
        case .localAccountDisabled:
            return "localAccountDisabled"
        case .localAccountDoesNotExist:
            return "localAccountDoesNotExist"
        case .localAccountNeedsUpdate:
            return "localAccountNeedsUpdate"
        case .localAccountInvalid:
            return "localAccountInvalid"
        case .attachmentUploadFailure:
            return "attachmentUploadFailure"
        case .attachmentDownloadFailure:
            return "attachmentDownloadFailure"
        case .messageAttachmentUploadFailure:
            return "messageAttachmentUploadFailure"
        case .messageAttachmentDownloadFailure:
            return "messageAttachmentDownloadFailure"
        case .systemNeedsUpdate:
            return "systemNeedsUpdate"
        case .serviceCrashed:
            return "serviceCrashed"
        case .invalidLocalCredentials:
            return "invalidLocalCredentials"
        case .attachmentDownloadFailureFileNotFound:
            return "attachmentDownloadFailureFileNotFound"
        case .textRenderingPreflightFailed:
            return "textRenderingPreflightFailed"
        @unknown default:
            return "unknown(\(rawValue)"
        }
    }
}

public struct Message: ChatItemOwned, CustomDebugStringConvertible, Hashable {
    static func message(withGUID guid: String, in chatID: String? = nil) -> Promise<Message?> {
        IMMessage.message(withGUID: guid, in: chatID).then {
            $0 as? Message
        }
    }
    
    static func messages(withGUIDs guids: [String], in chat: String? = nil) -> Promise<[Message]> {
        IMMessage.messages(withGUIDs: guids, in: chat).compactMap {
            $0 as? Message
        }
    }
    
    public static func messages(matching query: String, limit: Int) -> Promise<[Message]> {
        DBReader.shared.messages(matching: query, limit: limit)
            .then { guids in BLLoadChatItems(withGUIDs: guids) }
            .compactMap { $0 as? Message }
    }
    
    public static let ingestionClasses: [NSObject.Type] = [IMItem.self, IMMessage.self, IMMessageItem.self, IMAssociatedMessageItem.self]
    
    public init?(ingesting item: NSObject, context: IngestionContext) {
        switch item {
        case let item as IMMessageItem:
            if let message = context.message {
                self.init(item, message: message, items: context.items(forMessageItem: item), chatID: context.chatID)
            } else {
                self.init(item, items: context.items(forMessageItem: item), chatID: context.chatID)
            }
        case let message as IMMessage:
            self.init(message, items: context.items(forMessage: message), chatID: context.chatID)
        default:
            return nil
        }
    }
    
    // SPI for CBDaemonListener ONLY
    init(messageItem item: IMMessageItem, chatID: String, items: [AnyChatItem]? = nil) {
        id = item.id
        self.chatID = chatID
        fromMe = item.isFromMe()
        time = item.effectiveTime
        threadIdentifier = item.threadIdentifier()
        threadOriginator = item.threadOriginatorID
        subject = item.subject
        isSOS = item.isSOS
        isTypingMessage = item.isTypingMessage
        isCancelTypingMessage = item.isCancelTypingMessage()
        isDelivered = item.isDelivered
        isAudioMessage = item.isAudioMessage
        flags = .init(rawValue: item.flags)
        self.items = items ?? IngestionContext(chatID: chatID).ingest(item.chatItems).map {
            $0.eraseToAnyChatItem()
        }
        service = item.resolveServiceStyle(inChat: chatID)
        sender = item.resolveSenderID(inService: service)
        associatedMessageID = item.associatedMessageGUID()
        fileTransferIDs = item.fileTransferGUIDs
        description = item.message()?.description(forPurpose: .SPI, in: IMChat.resolve(withIdentifier: chatID), senderDisplayName: nil)
        failureCode = item.errorCode
        failed = failureCode != .noError
        failureDescription = failureCode.description
        item.receipt.assign(toMessage: &self)
    }

    init(_ item: IMItem, transcriptRepresentation: ChatItem, chatID: String? = nil, additionalFileTransferGUIDs: [String] = []) {
        id = item.id
        self.chatID = chatID ?? transcriptRepresentation.chatID
        fromMe = item.isFromMe
        time = item.effectiveTime
        threadIdentifier = item.threadIdentifier
        threadOriginator = item.threadOriginatorID
        subject = nil
        isSOS = false
        isTypingMessage = false
        isCancelTypingMessage = false
        isDelivered = true
        isAudioMessage = false
        flags = 0x5
        items = [transcriptRepresentation.eraseToAnyChatItem()]
        service = item.resolveServiceStyle(inChat: chatID)
        sender = item.resolveSenderID(inService: service)
        associatedMessageID = item.associatedMessageGUID()
        fileTransferIDs = additionalFileTransferGUIDs
        failureCode = .noError
        failed = false
        failureDescription = failureCode.description
        item.bareReceipt.assign(toMessage: &self)
    }
    
    init(_ backing: IMMessageItem?, message: IMMessage, items chatItems: [ChatItem], chatID: String) {
        id = message.id
        self.chatID = chatID
        fromMe = message.isFromMe
        time = message.effectiveTime
        service = backing?.resolveServiceStyle(inChat: chatID) ?? message.resolveServiceStyle(inChat: chatID)
        sender = message.resolveSenderID(inService: service)
        subject = message.subject?.id
        messageSubject = backing?.subject ?? message.messageSubject?.string
        isSOS = backing?.isSOS ?? message.isSOS
        isTypingMessage = backing?.isTypingMessage ?? message.isTypingMessage ?? chatItems.contains {
            $0 is TypingItem
        }
        
        isCancelTypingMessage = backing?.isCancelTypingMessage() ?? false
        isDelivered = backing?.isDelivered ?? message.isDelivered
        isAudioMessage = backing?.isAudioMessage ?? message.isAudioMessage
        items = chatItems.map { $0.eraseToAnyChatItem() }
        flags = IMMessageFlags(rawValue: backing?.flags ?? message.flags)
        associatedMessageID = backing?.associatedMessageGUID() ?? message.associatedMessageGUID
        fileTransferIDs = message.fileTransferGUIDs
        failureCode = backing?.errorCode ?? message._imMessageItem?.errorCode ?? FZErrorType.noError
        failed = failureCode != .noError
        failureDescription = failureCode.description
        
        if let chat = IMChat.resolve(withIdentifier: chatID) {
            description = try? message.description(forPurpose: .conversationList, in: chat)
        }
        
        // load timestamps
        message.receipt.merging(receipt: backing?.receipt ?? message.receipt).assign(toMessage: &self)
        self.load(message: message, backing: backing)
    }
    
    init(_ backing: IMMessageItem, items: [ChatItem], chatID: String) {
        if let message = backing.message() ?? IMMessage.message(fromUnloadedItem: backing) {
            self.init(backing, message: message, items: items, chatID: chatID)
        } else {
            self.init(messageItem: backing, chatID: chatID, items: items.map { $0.eraseToAnyChatItem() })
        }
    }
    
    init(_ message: IMMessage, items: [ChatItem], chatID: String) {
        self.init(message._imMessageItem, message: message, items: items, chatID: chatID)
    }
    
    private mutating func load(message: IMMessage?, backing: IMMessageItem?) {
        if #available(iOS 14, macOS 10.16, watchOS 7, *) {
            if let rawThreadIdentifier = message?.threadIdentifier() ?? backing?.threadIdentifier {
                guard let (threadIdentifier, threadOriginatorPart) = CBExtractThreadOriginatorAndPartFromIdentifier(rawThreadIdentifier) else {
                    return
                }
                
                self.threadIdentifier = threadIdentifier
                self.threadOriginator = threadIdentifier
                self.threadOriginatorPart = threadOriginatorPart
            }
        }
    }
    
    public var id: String
    public var chatID: String
    public var fromMe: Bool
    public var time: Double
    public var sender: String?
    public var subject: String?
    public var timeDelivered: Double = 0
    public var timePlayed: Double = 0
    public var timeRead: Double = 0
    public var messageSubject: String?
    public var isSOS: Bool
    public var isTypingMessage: Bool
    public var isCancelTypingMessage: Bool
    public var isDelivered: Bool
    public var isAudioMessage: Bool
    public var description: String?
    public var flags: IMMessageFlags
    public var failed: Bool
    public var failureCode: FZErrorType
    public var failureDescription: String
    public var items: [AnyChatItem]
    public var service: IMServiceStyle
    public var fileTransferIDs: [String]
    public var associatedMessageID: String?
    public var threadIdentifier: String?
    public var threadOriginator: String?
    public var threadOriginatorPart: Int?
    
    public var debugDescription: String {
        String(format: "Message(id=%@,sender=%@,typing=%d,items=[%@])", id, sender ?? "(nil)", isTypingMessage, items.map(\.debugDescription).joined(separator: ", "))
    }
    
    public var imChat: IMChat {
        IMChat.resolve(withIdentifier: chatID)!
    }
    
    public var chat: Chat {
        Chat(imChat)
    }
    
    public var associableItemIDs: [String] {
        items.filter { item in
            item.type == .text || item.type == .attachment || item.type == .plugin
        }.map(\.id)
    }
    
    public var type: ChatItemType {
        .message
    }
}

public extension Message {
    /// Returns a refreshed copy of the message
    func refresh() -> Message {
        guard let item = BLLoadIMMessageItem(withGUID: id) else {
            return self
        }
        
        return Message(messageItem: item, chatID: chatID)
    }
}
