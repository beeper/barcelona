//
//  CBChat.swift
//  Barcelona
//
//  Created by Eric Rabil on 8/8/22.
//

import Foundation
import Combine
import IMFoundation

/// An entity tracking a single logical conversation comprised of potentially several different chats
public class CBChat {
    private static let log = Logger(category: "CBChat", subsystem: "com.beeper.imc.paris")
    /// All cached messages for this chat
    public internal(set) var messages: [String: CBMessage] = [:]
    /// The style of this chat
    public internal(set) var style: CBChatStyle
    
    private var subscribers: Set<AnyCancellable> = Set()
    
    public init(style: CBChatStyle) {
        self.style = style
        $leaves.sink { [weak self] leaves in
            self?.refreshIdentifiers(leaves)
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
    
    /// Immediately calculates and updates the latest value for the chat identifiers
    private func refreshIdentifiers(_ leaves: [String: CBChatLeaf]? = nil) {
        let currentIdentifiers = calculateIdentifiers(leaves)
        if currentIdentifiers == identifiers {
            return
        }
        identifiers = currentIdentifiers
    }
    
    /// Handle a chat update in dictionary representation
    public func handle(dictionary: [AnyHashable: Any]) {
        guard let guid = dictionary["guid"] as? String else {
            return
        }
        leaves[guid, default: CBChatLeaf()].handle(dictionary: dictionary)
    }
}

extension CBChat {
    @_transparent var log: Logger { CBChat.log }
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
        var identifiers: Set<String> = Set(), chats: Set<IMChat> = Set()
        func addListener(_ chatIdentifier: String) -> String {
            guard identifiers.insert(chatIdentifier).inserted else {
                return chatIdentifier
            }
            CBChatRegistry.shared.loadedChatsByChatIdentifierCallback[chatIdentifier, default: []].append { loadedChats in
                for chat in loadedChats {
                    chats.insert(chat)
                }
                identifiers.remove(chatIdentifier)
            }
            IMDaemonController.shared().loadChat(withChatIdentifier: chatIdentifier)
            return chatIdentifier
        }
        for leaf in leaves.values {
            if let existing = IMChatRegistry.shared.existingChat(withGUID: leaf.guid), existing.guid == leaf.guid {
                continue
            }
            _ = addListener(leaf.chatIdentifier)
        }
        return leaves.values.compactMap(\.IMChat)
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
    
    var serviceForSending: IMService {
        chatForSending().account.service ?? .init()
    }
    
    func chatForSending(on service: CBServiceName = .iMessage) -> IMChat {
        let IMChats = IMChats, service = participants.contains(where: \.isEmail) ? .iMessage() : service.IMServiceStyle.service
        if style == .instantMessage {
            let recipients = IMChats.compactMap(\.recipient).filter { $0.service == service }
            let recipient = IMHandle.bestIMHandle(in: recipients) ?? recipients.first
            let recipientChats = IMChats.filter { $0.recipient == recipient }.sorted {
                let account0 = $0.account
                let account1 = $1.account
                return account0?.service != account1?.service && account0?.service == service
            }
            if let chat = recipientChats.first {
                if chat.account.service != service {
                    log.fault("Failed to reconcile chat for sending on service \(service?.name ?? "nil", privacy: .public), I will retarget \(chat.debugDescription, privacy: .private) instead")
                    chat._target(toService: service, newComposition: true)
                    chat._setAccount(IMAccountController.shared.bestAccount(forService: service))
                }
                return chat
            } else {
                log.fault("Failed to reconcile chat for sending on service \(service?.name ?? "nil", privacy: .public)")
                return IMChats[0]
            }
        } else {
            return IMChats.first(where: { $0.account.service == service }) ?? IMChats.first!
        }
    }
}

// MARK: - Message sending
public extension CBChat {
    func send(message: IMMessage, chat: IMChat? = nil) {
        let chat = chat ?? chatForSending()
        chat.send(message)
    }
    
    func send(message: IMMessageItem, chat: IMChat? = nil) {
        send(message: IMMessage(fromIMMessageItem: message, sender: nil, subject: nil), chat: chat)
    }
    
    func send(message: CreateMessage) throws -> IMMessage {
        let chat = chatForSending()
        let message = try message.imMessage(inChat: chat.chatIdentifier)
        send(message: message, chat: chat)
        return message
    }
    
    func send(message: String) throws {
        try send(message: CreateMessage(parts: [.init(type: .text, details: message)]))
    }
}
#endif
