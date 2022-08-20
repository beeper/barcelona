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
    
    @Published public internal(set) var mergedID: String = ""
    
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
        chatForSending()?.account.service ?? .sms()
    }
    
    func bestRecipient(on service: IMServiceImpl = .iMessage()) -> IMHandle? {
        guard style == .instantMessage else {
            log.error("Ignoring request to query best recipient in a group chat")
            return nil
        }
        var recipientsByID: [String: IMHandle] = [:]
        let IMChats = IMChats
        lazy var deduplicatedRecipientIDs: [String] = {
            var ids: Set<String> = Set()
            for chat in IMChats {
                guard let recipient = chat.recipient else {
                    log.warn("\(chat.id) has no recipient!")
                    continue
                }
                ids.insert(recipient.id)
            }
            log.info("Deduplicated recipient IDs for \(self.mergedID): \(ids)")
            return Array(ids)
        }()
        lazy var statuses: [String: IDSState] = {
            do {
                let statuses = try BLResolveIDStatusForIDs(deduplicatedRecipientIDs, onService: service.id)
                if statuses.count < deduplicatedRecipientIDs.count {
                    // Some results were not returned, lets sanity check and log any missing IDs
                    for recipientID in deduplicatedRecipientIDs {
                        if !statuses.keys.contains(recipientID) {
                            log.warn("ID status query for chat \(self.mergedID) did not return results for \(recipientID)")
                        }
                    }
                }
                return statuses
            } catch {
                log.fault("Error while resolving ID status for \(deduplicatedRecipientIDs.joined(separator: ",")) in \(self.mergedID): \(String(describing: error))")
                return [:]
            }
        }()
        for chat in IMChats {
            guard let recipient = chat.recipient else {
                log.debug("Skip chat \(chat.id): recipient is missing")
                continue
            }
            guard !recipientsByID.keys.contains(recipient.id) else {
                log.debug("Skip chat \(chat.id): already visited")
                continue
            }
            let idsStatus = statuses[recipient.id]
            guard statuses[recipient.id] == .available else {
                log.info("Skip recipient \(recipient.id): IDS status is \(idsStatus?.description ?? "nil")")
                continue
            }
            log.info("\(recipient.id) is available on \(service.name)")
            recipientsByID[recipient.id] = recipient
        }
        let recipients = Array(recipientsByID.values)
        let recipientCount = recipients.count
        log.info("There are \(recipientCount, privacy: .public) recipients to choose from: \(recipientsByID.keys.joined(separator: ","))")
        func compareHandles(_ handle1: IMHandle, _ handle2: IMHandle) -> Bool {
            lazy var handle1PN = handle1.id.isPhoneNumber
            lazy var handle2PN = handle2.id.isPhoneNumber
            if handle1PN {
                if handle2PN {
                    return false
                }
                return true
            } else {
                return false
            }
        }
        if let bestRecipient = recipients.sorted(by: compareHandles(_:_:)).first {
            log.info("Choosing \(bestRecipient.id) for sending messages")
            return bestRecipient
        }
        return nil
    }
    
    
    
    func chatForSending(on service: CBServiceName = .iMessage) -> IMChat? {
        let IMChats = IMChats, service = service.service!
        if style == .instantMessage {
            func findBestRecipient() -> IMHandle? {
                guard var recipient = bestRecipient(on: service) else {
                    if service == .iMessage(), IMAccountController.shared.activeSMSAccount?.canSendMessages == true, let recipient = bestRecipient(on: .sms()) {
                        log.info("Can't reach \(self.mergedID) over \(service.name ?? "nil"), but SMS is working. Retargeting!")
                        return recipient
                    }
                    log.fault("Failed to determine best recipient in chat \(self.mergedID) for service \(service.name ?? "nil", privacy: .public)")
                    return nil
                }
                if recipient.service != service {
                    recipient = IMAccountController.shared.bestAccount(forService: service).map {
                        $0.imHandle(withID: recipient.id)
                    } ?? recipient
                }
                return recipient
            }
            guard let recipient = findBestRecipient() else {
                return nil
            }
            return (IMChatRegistry.shared.existingChat(forIMHandle: recipient, allowRetargeting: true) as? IMChat) ?? IMChatRegistry.shared.chat(for: recipient)
        } else {
            return IMChats.first(where: { $0.account.service == service })
        }
    }
}

// MARK: - Message sending
public extension CBChat {
    func send(message: IMMessage, chat: IMChat? = nil) -> Bool {
        guard let chat = chat ?? chatForSending() else {
            return false
        }
        chat.send(message)
        return true
    }
    
    func send(message: IMMessageItem, chat: IMChat? = nil) -> Bool {
        send(message: IMMessage(fromIMMessageItem: message, sender: nil, subject: nil), chat: chat)
    }
    
    func send(message: CreateMessage) throws -> IMMessage {
        guard let chat = chatForSending() else {
            throw BarcelonaError(code: 400, message: "You can't send messages to this chat. If this is an SMS, make sure forwarding is still enabled. If this is an iMessage, check your connection to Apple.")
        }
        let message = try message.imMessage(inChat: chat.chatIdentifier)
        _ = send(message: message, chat: chat)
        return message
    }
    
    func send(message: String) throws -> IMMessage {
        try send(message: CreateMessage(parts: [.init(type: .text, details: message)]))
    }
}
#endif
