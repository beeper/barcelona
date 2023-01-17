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
import IMFoundation

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
        CBLoggingFlags.if(\.ingestion, CLDebug("IngestionContext", "Ingesting items: \(items, privacy: .private)"))
        
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
    public var localizedDescription: String? {
        switch self {
        case .noError:
            return nil
        case .cancelled:
            return "Your message was interrupted while being sent."
        case .timeout:
            return "Your message took too long to send."
        case .networkFailure, .networkLookupFailure, .networkConnectionFailure, .noNetworkFailure, .networkBusyFailure, .networkDeniedFailure:
            return "Your message couldn't be sent due to a network connectivity issue."
        case .serverSignatureError:
            return "A secure connection cannot be established with iMessage, so your message will not be sent."
        case .serverDecodeError, .serverParseError, .serverInternalError, .serverInvalidRequestError, .serverMalformedRequestError, .serverUnknownRequestError, .serverRejectedError:
            return "The iMessage servers are having some trouble, please try again later."
        case .serverInvalidTokenError:
            return "The iMessage servers are rejecting your token. You may have to sign out and sign back in."
        case .remoteUserInvalid:
            return "The address you are trying to send a message to is invalid."
        case .remoteUserDoesNotExist:
            return "The address you are trying to send a message to is not registered for this service."
        case .remoteUserIncompatible:
            return "The address you are trying to send a message to cannot be reached using this mechanism."
        case .remoteUserRejected:
            return "The address you are trying to send a message to is rejecting your message."
        case .transcodingFailure:
            return "Your attachment failed to transcode."
        case .encryptionFailure:
            return "Your message couldn't be sent due to an iMessage encryption error."
        case .otrEncryptionFailure:
            return "Your message couldn't be sent due to an iMessage OTR encryption error."
        case .decryptionFailure:
            return "Your message couldn't be sent due to an iMessage decryption error."
        case .otrDecryptionFailure:
            return "Your message couldn't be sent due to an iMessage OTR decryption error."
        case .localAccountDisabled, .localAccountDoesNotExist, .localAccountNeedsUpdate, .localAccountInvalid, .invalidLocalCredentials:
            return "Your message couldn't be sent due to an issue with your account. You may have to sign out and sign back in."
        case .attachmentDownloadFailure, .messageAttachmentDownloadFailure:
            return "This message is missing an attachment that failed to download."
        case .attachmentUploadFailure, .messageAttachmentUploadFailure:
            return "Your message couldn't be sent because your attachment failed to upload to iMessage."
        case .systemNeedsUpdate:
            return "Your message couldn't be sent because the system iMessage is running on is too outdated."
        case .serviceCrashed:
            return "Your message couldn't be sent because imagent is crashing."
        case .attachmentDownloadFailureFileNotFound:
            return "The attachment couldn't be downloaded because it is no longer available."
        case .textRenderingPreflightFailed:
            return "The message couldn't be processed because it is corrupted."
        case .unknownError, .sendFailed, .internalFailure:
            fallthrough
        @unknown default:
            return "Your message couldn't be sent due to an unknown error."
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
    @_spi(unitTestInternals) public init(id: String, chatID: String, fromMe: Bool, time: Double, sender: String? = nil, subject: String? = nil, timeDelivered: Double = 0, timePlayed: Double = 0, timeRead: Double = 0, messageSubject: String? = nil, isSOS: Bool, isTypingMessage: Bool, isCancelTypingMessage: Bool, isDelivered: Bool, isAudioMessage: Bool, isRead: Bool = false, description: String? = nil, flags: IMMessageFlags, failed: Bool, failureCode: FZErrorType, failureDescription: String, items: [AnyChatItem], service: IMServiceStyle, fileTransferIDs: [String], associatedMessageID: String? = nil, threadIdentifier: String? = nil, threadOriginator: String? = nil, threadOriginatorPart: Int? = nil) {
        self.id = id
        self.chatID = chatID
        self.fromMe = fromMe
        self.time = time
        self.sender = sender
        self.subject = subject
        self.timeDelivered = timeDelivered
        self.timePlayed = timePlayed
        self.timeRead = timeRead
        self.messageSubject = messageSubject
        self.isSOS = isSOS
        self.isTypingMessage = isTypingMessage
        self.isCancelTypingMessage = isCancelTypingMessage
        self.isDelivered = isDelivered
        self.isAudioMessage = isAudioMessage
        self.isRead = isRead
        self.description = description
        self.flags = flags
        self.failed = failed
        self.failureCode = failureCode
        self.failureDescription = failureDescription
        self.items = items
        self.service = service
        self.fileTransferIDs = fileTransferIDs
        self.associatedMessageID = associatedMessageID
        self.threadIdentifier = threadIdentifier
        self.threadOriginator = threadOriginator
        self.threadOriginatorPart = threadOriginatorPart
    }
    
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
        threadIdentifier = item.threadIdentifier
        threadOriginator = item.threadOriginatorID
        subject = item.subject
        isSOS = item.isSOS
        isTypingMessage = item.isTypingMessage
        isCancelTypingMessage = item.isCancelTypingMessage()
        isDelivered = item.isDelivered
        isAudioMessage = item.isAudioMessage
        isRead = item.isRead
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
        metadata = item.metadata
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
        isRead = false
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
        isTypingMessage = backing?.isTypingMessage ?? message.isTypingMessage
        isCancelTypingMessage = backing?.isCancelTypingMessage() ?? false
        isDelivered = backing?.isDelivered ?? message.isDelivered
        isAudioMessage = backing?.isAudioMessage ?? message.isAudioMessage
        items = chatItems.map { $0.eraseToAnyChatItem() }
        isRead = backing?.isRead ?? message.isRead
        flags = IMMessageFlags(rawValue: backing?.flags ?? message.flags)
        associatedMessageID = backing?.associatedMessageGUID() ?? message.associatedMessageGUID
        fileTransferIDs = message.fileTransferGUIDs
        failureCode = backing?.errorCode ?? message._imMessageItem?.errorCode ?? FZErrorType.noError
        failed = failureCode != .noError
        failureDescription = failureCode.description
        
        if let chat = IMChat.resolve(withIdentifier: chatID) {
            description = message.description(forPurpose: .conversationList, in: chat)
        }
        
        // load timestamps
        message.receipt.merging(receipt: backing?.receipt ?? message.receipt).assign(toMessage: &self)
        self.load(message: message, backing: backing)
        metadata = backing?.metadata ?? message.metadata
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
    public var isRead: Bool
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
    public var metadata: Metadata?

    public var isFinished: Bool {
        flags.contains(.finished)
    }
    
    public var isSent: Bool {
        flags.contains(.sent)
    }
    
    public var hasTranscriptItems: Bool {
        items.contains(where: \.isTranscriptItem)
    }
    
    public var isFromMe: Bool {
        fromMe
    }
    
    public var debugDescription: String {
        String(format: "Message(id=%@,sender=%@,typing=%d,items=[%@],failed=%d,sent=%d,error=%d)", id, sender ?? "(nil)", isTypingMessage, items.map(\.debugDescription).joined(separator: ", "), failed, isSent, errorCode.rawValue)
    }
    
    public var imChat: IMChat! {
        IMChat.resolve(withIdentifier: chatID)
    }
    
    public var chat: Chat! {
        imChat.map(Chat.init(_:))
    }
    
    public var associableItemIDs: [String] {
        items.filter { item in
            item.type == .text || item.type == .attachment || item.type == .plugin
        }.map(\.id)
    }
    
    public var type: ChatItemType {
        .message
    }
    
    public var isReadByMe: Bool {
        if fromMe {
            CLDebug("ReadState", "\(id) on service \(service.rawValue) with sender \(sender ?? "nil") is read because it is from me")
            return true
        }
        if timeRead > 0 {
            CLDebug("ReadState", "\(id) on service \(service.rawValue) with sender \(sender ?? "nil") is read because time read is non-zero")
            return true
        }
        /// BRI-4711: `isRead` may be erroneously true; use `timeRead` as the source of truth for now
        /*if isRead {
            CLDebug("ReadState", "\(id) on service \(service.rawValue) with sender \(sender ?? "nil") is read because isRead == true")
            return true
        }*/
        if CBFeatureFlags.useSMSReadBuffer && CBDaemonListener.shared.smsReadBuffer.contains(id) {
            CLDebug("ReadState", "\(id) on service \(service.rawValue) with sender \(sender ?? "nil") is read because read buffer contains ID")
            return true
        }
        return false
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

extension MessageAttributes {
    static let metadataAttribute: NSAttributedString.Key = .init("com.ericrabil.metadata")
}

public protocol IMMessageSummaryInfoProvider: NSObjectProtocol {
    var messageSummaryInfo: [AnyHashable: Any]! { get set }
    var sourceApplicationID: String! { get set }
}

extension IMMessageItem: IMMessageSummaryInfoProvider {}
extension IMMessage: IMMessageSummaryInfoProvider {}

extension IMMessageSummaryInfoProvider {
    public var sourceApplicationID: String! {
        get { messageSummaryInfo?["amsa"] as? String }
        set {
            if messageSummaryInfo == nil {
                messageSummaryInfo = [:]
            }
            messageSummaryInfo["amsa"] = newValue
        }
    }
}

let metadataPrefix = "com.ericrabil.barcelona.metadata:00000000:"
public extension IMMessageSummaryInfoProvider {
    
    func calculateMetadata() -> Message.Metadata {
        guard let sourceApplicationID = sourceApplicationID, sourceApplicationID.starts(with: metadataPrefix) else {
            return [:]
        }
        do {
            return try PropertyListDecoder().decode(Message.Metadata.self, from: Data(base64Encoded: String(sourceApplicationID.dropFirst(metadataPrefix.count)))!)
        } catch {
            print(error, sourceApplicationID.dropFirst(metadataPrefix.count))
            return [:]
        }
    }
    
    var metadata: Message.Metadata {
        get {
            if sourceApplicationID == nil {
                return [:]
            }
            switch objc_getAssociatedObject(self, "com.ericrabil.metadata") {
            case .some(let metadataValue as Message.Metadata):
                return metadataValue
            default:
                objc_setAssociatedObject(self, "com.ericrabil.metadata", calculateMetadata(), .OBJC_ASSOCIATION_RETAIN)
                return self.metadata
            }
        }
        set {
            if newValue == self.metadata {
                return
            }
            let encoder = PropertyListEncoder()
            encoder.outputFormat = .binary
            let data = try! encoder.encode(newValue)
            sourceApplicationID = metadataPrefix + data.base64EncodedString()
            objc_setAssociatedObject(self, "com.ericrabil.metadata", newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
}

public extension Message {
    typealias Metadata = [String: MetadataValue]
}
