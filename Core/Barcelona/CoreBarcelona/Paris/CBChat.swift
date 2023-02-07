//
//  CBChat.swift
//  Barcelona
//
//  Created by Eric Rabil on 8/8/22.
//

import Foundation
import Combine
import IMFoundation
import IMSharedUtilities
import Logging

/// An entity tracking a single logical conversation comprised of potentially several different chats
public class CBChat {
    private let log = Logger(label: "CBChat")
    /// All cached messages for this chat
    public internal(set) var messages: [String: CBMessage] = [:]
    /// The style of this chat
    public internal(set) var style: CBChatStyle
    
    private var subscribers: Set<AnyCancellable> = Set()
    
    public init(style: CBChatStyle) {
        self.style = style
        $leaves.sink { [weak self] leaves in
            self?.refreshIdentifiers(leaves)
            self?.refreshParticipants(leaves)
        }.store(in: &subscribers)
    }
    
    /// A merged array of all chat identifiers this conversation tracks
    public var chatIdentifiers: [String] {
        leaves.values.lazy.map(\.chatIdentifier).filter { !$0.isEmpty }
    }
    
    /// All chats this conversation is comprised of
    @Published public internal(set) var leaves: [String: CBChatLeaf] = [:]
    
    /// Immediately calculates all identifiers for this chat
    private func calculateIdentifiers(_ leaves: [String: CBChatLeaf]? = nil) -> Set<CBChatIdentifier> {
        var identifiers = (leaves ?? self.leaves).values.reduce(into: Set<CBChatIdentifier>()) { identifiers, leaf in
            leaf.forEachIdentifier {
                identifiers.insert($0)
            }
        }
        for identifier in identifiers {
            switch identifier.scheme {
            case .guid:
                guard !identifier.value.isEmpty else {
                    continue
                }
                var components = identifier.value.split(separator: ";").map(String.init(_:))
                switch components[0] {
                case "iMessage":
                    components[0] = "SMS"
                default:
                    components[0] = "iMessage"
                }
                identifiers.insert(.guid(components.joined(separator: ";")))
                continue
            default:
                continue
            }
        }
        return identifiers
    }
    
    /// All chat identifiers that should match against this conversation
    @Published public internal(set) var identifiers: Set<CBChatIdentifier> = Set()
    
    @Published public internal(set) var mergedID: String = ""
    
    @Published public internal(set) var mergedRecipientIDs: Set<String> = []
    
    private func refreshParticipants(_ leaves: [String: CBChatLeaf]? = nil) {
        let leaves = leaves ?? self.leaves
        guard style == .instantMessage else {
            mergedRecipientIDs = []
            return
        }
        mergedRecipientIDs = leaves.values.reduce(into: Set()) { recipients, leaf in
            if let last = leaf.participants.last {
                recipients.insert(last.personID)
            }
        }
    }
    
    /// Immediately calculates and updates the latest value for the chat identifiers
    private func refreshIdentifiers(_ leaves: [String: CBChatLeaf]? = nil) {
        let currentIdentifiers = calculateIdentifiers(leaves)
        if currentIdentifiers == identifiers {
            return
        }
        identifiers = currentIdentifiers
        mergedID = identifiers.filter {
            $0.scheme == .chatIdentifier
        }.map(\.value).sorted(by: >).joined(separator: ",")
    }
    
    /// Handle a chat update in dictionary representation
    public func handle(dictionary: [AnyHashable: Any]) {
        guard let guid = dictionary["guid"] as? String else {
            return
        }
        leaves[guid, default: CBChatLeaf()].handle(dictionary: dictionary)
    }
}

public struct CBChatParticipant {
    public var countryCode: String?
    public var unformattedName: String?
    public var personID: String
    
    public init?(dictionary: [AnyHashable: Any]) {
        guard let personID = dictionary["FZPersonID"] as? String else {
            return nil
        }
        self.personID = personID
        self.unformattedName = dictionary["FZPersonUnformattedName"] as? String
        self.countryCode = dictionary["FZPersonCountryCode"] as? String
    }
}

public extension CBChat {
    var sortedMessages: [CBMessage] {
        messages.values.lazy.sorted(by: >)
    }
    
    /// Returns the most recent message matching the given flags
    func lastMessage(with flags: CBMessage.Flags) -> CBMessage? {
        sortedMessages.first(where: { $0.flags.contains(flags) })
    }
}

extension CBMessage {
    /// Whether the message was sent by me.
    var isFromMe: Bool {
        flags.contains(.fromMe)
    }
    
    /// Whether the message was successfully delivered.
    var isDelivered: Bool {
        flags.contains(.delivered)
    }
    
    /// Whether the message is finished sending.
    var isFinished: Bool {
        flags.contains(.finished)
    }
    
    /// Whether the message was successfully sent. Still true if an error was encountered after sending.
    var isSent: Bool {
        flags.contains(.sent)
    }
    
    /// Whether this message was sent over SMS.
    var isSMS: Bool {
        service == .SMS
    }
    
    /// Whether this message was sent over iMessage.
    var isMadrid: Bool {
        service == .iMessage
    }
    
    /// Whether this message has any non-successful error code.
    var hasError: Bool {
        error != .noError
    }
    
    /// Whether this message was successfuly sent to the recipient.
    var isSuccessful: Bool {
        guard !hasError && isFinished else {
            return false
        }
        guard isFromMe else {
            return false
        }
        if isSMS {
            return isSent
        } else {
            return isDelivered
        }
    }
}

public extension CBChat {
    var successfulMessages: [CBMessage] {
        sortedMessages.filter(\.isSuccessful).sorted(by: >)
    }
}

#if canImport(IMCore)
import IMCore

public extension CBChat {
    var IMChats: [IMChat] {
        leaves.values.compactMap(\.IMChat)
    }
    
    var participants: [String] {
        leaves.values.first?.participants.map(\.personID) ?? []
    }
    
    var canonicalIDSParticipants: [String] {
        leaves.values.first?.participants.map(\.personID).map { ($0 as NSString)._bestGuessURI() as! String } ?? []
    }
    
    var mostRecentChat: IMChat? {
        leaves.values.sorted(usingKey: \.lastSentMesageDate, by: >).first?.IMChat
    }
    
    var senderLastAddressedHandle: String? {
        mostRecentChat?.lastAddressedHandleID
    }
    
    var senderLastAddressedSIMID: String? {
        mostRecentChat?.lastAddressedSIMID
    }

    func chatForSending(with guid: String) -> IMChat? {
        IMChats.first(where: { $0.guid == guid })
    }
}

private extension IMHandle {
    var chat: IMChat? {
        IMChatRegistry.shared._existingChat(withIdentifier: id, style: 0x2d, account: service.internalName) ?? IMChatRegistry.shared.chat(for: self)
    }
}

// MARK: - Message sending
public extension CBChat {
    func send(message: IMMessage, chat: IMChat) {
        chat.send(message)
    }
    
    func send(message: IMMessageItem, chat: IMChat) {
        send(message: IMMessage(fromIMMessageItem: message, sender: nil, subject: nil), chat: chat)
    }
    
    func send(message: CreateMessage, guid: String, service: IMServiceStyle) throws -> IMMessage {
        guard let chat = chatForSending(with: guid) else {
            throw BarcelonaError(code: 400, message: "You can't send messages to this chat. If this is an SMS, make sure forwarding is still enabled. If this is an iMessage, check your connection to Apple.")
        }
        let message = try message.imMessage(inChat: chat.chatIdentifier, service: service)
        send(message: message, chat: chat)
        return message
    }
}
#endif
