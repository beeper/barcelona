//
//  CBMessage.swift
//  Barcelona
//
//  Created by Eric Rabil on 8/8/22.
//

import BarcelonaDB
import Foundation
import IMCore
import IMFoundation
import IMSharedUtilities
import Logging

private let log = Logger(label: "CBMessage")

public struct CBMessage: Codable, CustomDebugStringConvertible {
    /// The chat this message originated from
    public var chat: CBChatIdentifier
    /// The GUID of this message
    public var id: String
    /// The service this message originated from
    public var service: CBServiceName? = nil
    /// The sender who sent this message
    public var sender: CBSender = CBSender()
    /// The error for this message
    public var error: FZErrorType = .noError
    /// The time this message was realized
    public var time: Date?
    /// The time this message was read (by the recipient if `fromMe && !group`, otherwise by you)
    public var timeRead: Date?
    /// The time this message was delivered (to the recipient if `fromMe && !group`, otherwise to you)
    public var timeDelivered: Date?
    /// The bitflags for this message
    public var flags: Flags = .none

    /// Initializes the message from a dictionary representation
    public init?(dictionary: [AnyHashable: Any], chat: CBChatIdentifier) {
        guard let id = dictionary["guid"] as? String else {
            return nil
        }
        self.id = id
        self.chat = chat
        self.handle(dictionary: dictionary)
    }

    /// Updates the sender and timestamps according to the person who triggered the update
    public mutating func handle(
        time: Date?,
        timeDelivered: Date?,
        timeRead: Date?,
        sender deltaSender: CBSender
    ) -> CBMessage {
        if flags.contains(.fromMe) {
            if deltaSender.scheme != .me {
                self.timeDelivered = timeDelivered
                self.timeRead = timeRead
            }
            self.time = time ?? time
            self.sender = CBSender(scheme: .me, value: "")
        } else if deltaSender.scheme == .me {
            self.timeRead = timeRead
        } else {
            self.time = time
            self.timeDelivered = timeDelivered
            self.timeRead = timeRead
            self.sender = deltaSender
        }
        return updated()
    }

    /// Updates the message using a dictionary representation
    @discardableResult public mutating func handle(dictionary: [AnyHashable: Any]) -> CBMessage {
        service = (dictionary["service"] as? String).flatMap(CBServiceName.init(rawValue:)) ?? service
        error = (dictionary["error"] as? UInt32).flatMap(FZErrorType.init(rawValue:)) ?? error
        func extractTime(_ key: String) -> Date? {
            (dictionary[key] as? Double).flatMap(Date.init(timeIntervalSinceReferenceDate:))
        }
        flags.handle(dictionary: dictionary)
        return handle(
            time: extractTime("time"),
            timeDelivered: extractTime("timeDelivered"),
            timeRead: extractTime("timeRead"),
            sender: CBSender(dictionary: dictionary)
        )
    }

    private mutating func updated() -> CBMessage {
        if eligibleToResend {
            let id = id
            log.info("\(id) is eligible to resend, trying now")
            resend()
        }
        return self
    }

    /// An XML-like string describing the message
    public var debugDescription: String {
        """
        <CBMessage rawFlags=\(flags.rawValue) error=\(error) time=\(time?.description ?? "nil") timeDelivered=\(timeDelivered?.description ?? "nil") timeRead=\(timeRead?.description ?? "nil") sender=\(sender) \(flags.description)/>"
        """
    }
}

extension CBMessage {
    /// Abstraction for managing message flags via an `OptionSet`
    public struct Flags: OptionSet {
        public typealias RawValue = UInt32

        public let rawValue: RawValue

        public init(rawValue: RawValue) {
            self.rawValue = rawValue
        }
    }
}

extension CBMessage.Flags {
    /// No flags
    public static let none = Self(rawValue: 0)
    /// The message was successfully sent
    public static let sent = Self(rawValue: 1 << 0)
    /// The message was successfully delivered
    public static let delivered = Self(rawValue: 1 << 1)
    /// The message has been read
    public static let read = Self(rawValue: 1 << 2)
    /// The message was sent by me
    public static let fromMe = Self(rawValue: 1 << 3)
    /// The message has been downgraded to SMS
    public static let downgraded = Self(rawValue: 1 << 4)
    /// The message will be sent again
    public static let beingRetried = Self(rawValue: 1 << 5)
    /// The message is finished sending
    public static let finished = Self(rawValue: 1 << 6)
    public static let prepared = Self(rawValue: 1 << 7)
    /// The message was sent using the SOS feature
    public static let sos = Self(rawValue: 1 << 8)
    /// The message is an alert from the system
    public static let alert = Self(rawValue: 1 << 9)
    /// The message has been marked and reported as spam
    public static let spam = Self(rawValue: 1 << 10)
    /// The message should be presented as an emote (removed in Big Sur)
    public static let emote = Self(rawValue: 1 << 11)
    /// The message has been played (if it is an audio message)
    public static let played = Self(rawValue: 1 << 12)
    /// The message is corrupt and may be missing information
    public static let corrupt = Self(rawValue: 1 << 13)
    /// The message should expire once viewed
    public static let expirable = Self(rawValue: 1 << 14)
    /// The message should be presented as a waveform audio message
    public static let audioMessage = Self(rawValue: 1 << 15)
    /// The message should be presented as a location message
    public static let locationMessage = Self(rawValue: 1 << 16)
    /// The message has no contents, and is symbolic. Used for receipts and typing.
    public static let empty = Self(rawValue: 1 << 17)
    public static let reserved2 = Self(rawValue: 1 << 18)
    public static let reserved3 = Self(rawValue: 1 << 19)
    /// The message is a typing message when you have sent an empty message.
    public static let typing: Self = [.sent, .empty]

    /// Updates the bitmask state from dictionary representation
    public mutating func handle(dictionary: [AnyHashable: Any]) {
        let flags = IMMessageFlags(rawValue: dictionary["flags"] as? UInt64 ?? 0)
        flip(.sent, flags.contains(.sent))
        flip(.delivered, flags.contains(.delivered))
        flip(.read, flags.contains(.read))
        flip(.fromMe, flags.contains(.fromMe))
        flip(.downgraded, flags.contains(.downgraded))
        flip(.beingRetried, dictionary["isBeingRetried"] as? Bool ?? false)
        flip(.finished, flags.contains(.finished))
        flip(.prepared, flags.contains(.prepared))
        flip(.sos, dictionary["sos"] as? Bool ?? false)
        flip(.alert, flags.contains(.alert))
        flip(.spam, flags.contains(.spam))
        flip(.emote, flags.contains(.emote))
        flip(.played, flags.contains(.played))
        flip(.corrupt, flags.contains(.corrupt))
        flip(.expirable, flags.contains(.expirable))
        flip(.empty, flags.contains(.empty))
        //                flip(.acknowledgement, flags.contains(.ack))
        //                flip(.edit, flags.contains(.ed))
    }

    /// Flip a specific flag
    public mutating func flip(_ flag: Self, _ enabled: Bool) {
        if enabled {
            insert(flag)
        } else {
            remove(flag)
        }
    }

}

extension CBMessage.Flags: CaseIterable {
    public static let allCases: [CBMessage.Flags] = [
        .sent, .delivered, .typing, .read, .fromMe, .downgraded, .beingRetried, .finished, .prepared, .sos, .alert,
        .spam, .emote, .played, .corrupt, .expirable, .audioMessage, .locationMessage, .empty,
    ]
}

// MARK: - Flag descriptions
extension CBMessage.Flags {
    public var name: String {
        switch self {
        case .sent: return "sent"
        case .delivered: return "delivered"
        case .read: return "read"
        case .fromMe: return "fromMe"
        case .downgraded: return "downgraded"
        case .beingRetried: return "beingRetried"
        case .finished: return "finished"
        case .prepared: return "prepared"
        case .sos: return "sos"
        case .alert: return "alert"
        case .spam: return "spam"
        case .emote: return "emote"
        case .played: return "played"
        case .corrupt: return "corrupt"
        case .expirable: return "expirable"
        case .audioMessage: return "audioMessage"
        case .locationMessage: return "locationMessage"
        case .empty: return "empty"
        case .typing: return "typing"
        default: return rawValue.description
        }
    }
}

extension CBMessage.Flags: CustomStringConvertible {
    /// A human-readable string of the format `key=(true|false)` joined by spaces
    public var description: String {
        var strings: [String] = []
        for flag in Self.allCases {
            strings.append("\(flag.name)=\(contains(flag).description)")
        }
        return strings.joined(separator: " ")
    }
}

// MARK: - Sorting
extension CBMessage: Comparable {
    public static func < (lhs: CBMessage, rhs: CBMessage) -> Bool {
        guard let ltime = lhs.time else {
            return false
        }
        guard let rtime = rhs.time else {
            return false
        }
        return ltime < rtime
    }

    public static func > (lhs: CBMessage, rhs: CBMessage) -> Bool {
        guard let ltime = lhs.time else {
            return true
        }
        guard let rtime = rhs.time else {
            return true
        }
        return ltime > rtime
    }
}

// MARK: - Codable flags
extension CBMessage.Flags: Codable {
    public init(from decoder: Decoder) throws {
        rawValue = try RawValue(from: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        try rawValue.encode(to: encoder)
    }
}

// MARK: - IMCore interop

extension CBMessage.Flags {
    /// Update flag state using an `IMMessageItem` object
    mutating func handle(item: IMMessageItem) {
        flip(.sent, item.isSent)
        flip(.delivered, item.isDelivered)
        flip(.read, item.isRead)
        flip(.fromMe, item.isFromMe())
        flip(.downgraded, item.wasDowngraded)
        flip(.beingRetried, item.isBeingRetried)
        flip(.finished, item.isFinished)
        flip(.prepared, item.isPrepared)
        flip(.sos, item.isSOS)
        flip(.alert, item.isAlert)
        flip(.spam, item.isSpam)
        flip(.emote, item.isEmote)
        flip(.played, item.isPlayed)
        flip(.corrupt, item.isCorrupt)
        flip(.expirable, item.isExpirable)
        flip(.empty, item.isEmpty)
        //                flip(.acknowledgement, item.isMessageAcknowledgment())
        //                flip(.edit, item.isMessageEdit())
    }

    /// Update flag state using an `IMItem` object
    @_disfavoredOverload mutating func handle(item: IMItem) {
        if let item = item as? IMMessageItem {
            return handle(item: item)
        }
        flip(.sent, false)
        flip(.delivered, false)
        flip(.read, false)
        flip(.fromMe, item.isFromMe)
        flip(.downgraded, false)
        flip(.beingRetried, false)
        flip(.finished, false)
        flip(.prepared, false)
        flip(.sos, false)
        flip(.alert, false)
        flip(.spam, false)
        flip(.emote, false)
        flip(.played, false)
        flip(.corrupt, false)
        flip(.expirable, false)
        flip(.empty, false)
    }

}

extension CBMessage {
    /// Initializes the message using an `IMItem` instance
    @_disfavoredOverload public init(item: IMItem, chat: CBChatIdentifier) {
        if let item = item as? IMMessageItem {
            self = CBMessage(item: item, chat: chat)
        } else {
            self.chat = chat
            self.id = item.id
            self.handle(item: item)
        }
    }

    /// Initializes the message using an `IMMessageItem` instance
    public init(item: IMMessageItem, chat: CBChatIdentifier) {
        self.id = item.id
        self.chat = chat
        self.handle(item: item)
    }

    /// Updates the message using an `IMItem` instance
    @discardableResult @_disfavoredOverload public mutating func handle(item: IMItem) -> CBMessage {
        if let item = item as? IMMessageItem {
            return handle(item: item)
        }
        service = item.serviceStyle.map(CBServiceName.init(style:)) ?? service
        error = .noError
        flags.handle(item: item)
        return handle(time: item.time, timeDelivered: nil, timeRead: nil, sender: CBSender(item: item))
    }

    /// Updates the message using an `IMMessageItem` instance
    @discardableResult public mutating func handle(item: IMMessageItem) -> CBMessage {
        service = item.serviceStyle.map(CBServiceName.init(style:)) ?? service
        error = item.errorCode
        flags.handle(item: item)
        return handle(
            time: item.time,
            timeDelivered: item.timeDelivered,
            timeRead: item.timeRead,
            sender: CBSender(item: item)
        )
    }
}

extension CBMessage {
    public func loadIMMessageItem() -> IMMessageItem? {
        switch BLLoadIMMessageItem(withGUID: id) {
        case .some(let message):
            return message
        case .none:
            log.warning("Failed to locate message \(id)")
            return nil
        }
    }
}

extension CBMessage {
    func locateCBChat() async -> CBChat? {
        switch await CBChatRegistry.shared.chats[chat] {
        case .some(let chat):
            return chat
        case .none:
            log.warning("Failed to locate chat \(chat.rawValue)")
            return nil
        }
    }
}

extension CBMessage {
    public var eligibleToResend: Bool {
        guard flags.contains(.fromMe) else {
            return false
        }
        guard !flags.contains(.sent) else {
            return false
        }
        guard !flags.contains(.beingRetried) else {
            return false
        }
        switch error {
        case .remoteUserDoesNotExist, .remoteUserIncompatible, .remoteUserInvalid, .remoteUserRejected:
            return true
        case .networkFailure, .networkBusyFailure, .networkDeniedFailure, .networkLookupFailure,
            .networkConnectionFailure, .noNetworkFailure:
            return false
        case .localAccountDisabled, .localAccountInvalid, .localAccountNeedsUpdate, .localAccountDoesNotExist:
            return false
        case .encryptionFailure, .otrEncryptionFailure, .decryptionFailure, .otrDecryptionFailure:
            return false
        case .sendFailed, .timeout, .serverInternalError, .internalFailure, .serviceCrashed:
            return false
        case .attachmentUploadFailure, .messageAttachmentUploadFailure:
            return false
        default:
            return false
        }
    }

    public func resend() {
        Task {
            guard let message = loadIMMessageItem() else {
                return
            }
            if message.isBeingRetried {
                log.info(
                    "Ignoring request to resend message \(String(describing: message.guid)), it is already being retried"
                )
                return
            }
            message.isBeingRetried = true
            IMDaemonController.sharedInstance().updateMessage(message)
            let id = id
            log.info("Loaded message item for \(id)")
            guard let chat = await locateCBChat() else {
                return
            }
            log.info("Located origin chat for \(id)")

            guard let imChat = chat.IMChats.first(where: { $0.hasStoredMessage(withGUID: id) }) else {
                log.info("Can't resend \(message.id) because all IMChats claim to not contain this message")
                #if canImport(IMFoundation) && canImport(BarcelonaDB)
                // only if we have CBDaemonListener
                if let style = service?.IMServiceStyle {
                    CBDaemonListener.shared.messagePipeline.send(
                        Message(
                            messageItem: message,
                            chatID: DBReader.shared.immediateChatIdentifier(forMessageGUID: message.id)
                                ?? chat.chatIdentifiers[0],
                            service: style
                        )
                    )
                }
                #endif
                return
            }

            log.info("I will re-send \(id) on \(String(describing: imChat.guid))")
            if service == .SMS {
                var messageFlags = IMMessageFlags(rawValue: message.flags)
                messageFlags.insert(.downgraded)
                message._updateFlags(messageFlags.rawValue)
                log.debug("Added downgraded flag to message \(id)")
                // let serviceName = service.IMServiceStyle.rawValue
                let serviceName = "SMS"
                message.account = serviceName
                log.debug("Changed account name for message \(id) to \(serviceName)")
                if let newAccountID = service?.IMServiceStyle.service.accountIDs.first as? String {
                    message.accountID = newAccountID
                    log.debug("Changed account ID for message \(id) to \(newAccountID)")
                } else {
                    log.warning("Failed to find valid account ID for re-sending message \(id), this is not good...")
                }
                message.service = serviceName
                IMDaemonController.sharedInstance().updateMessage(message)
                log.debug("Changed service for message \(id) to \(serviceName)")
            }
            guard imChat.account.serviceName == service?.IMServiceStyle.service.name else {
                log.error("Misaligned IMChat/IMMessage/CBChat service when trying to re-send message \(id)!!!!!!")
                return
            }
            log.info("Re-sending message \(id) on chat \(String(describing: imChat.guid))")
            await chat.send(message: message, chat: imChat)
        }
    }
}
