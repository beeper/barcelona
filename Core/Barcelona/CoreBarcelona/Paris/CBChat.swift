//
//  CBChat.swift
//  Barcelona
//
//  Created by Eric Rabil on 8/8/22.
//

import Combine
import Foundation
import IMFoundation
import IMSharedUtilities
import IMCore
import Logging

/// An entity tracking a single logical conversation comprised of potentially several different chats
public class CBChat {
    /// All cached messages for this chat
    public internal(set) var messages: [String: CBMessage] = [:]

    private var subscribers: Set<AnyCancellable> = Set()

    public init() {
        $leaves.sink { [weak self] leaves in
            self?.refreshIdentifiers(leaves)
        }
        .store(in: &subscribers)
    }

    /// A merged array of all chat identifiers this conversation tracks
    public var chatIdentifiers: [String] {
        leaves.values.lazy.map(\.chatIdentifier).filter { !$0.isEmpty }
    }

    /// All chats this conversation is comprised of
    @Published public internal(set) var leaves: [String: CBChatLeaf] = [:]

    /// Immediately calculates all identifiers for this chat
    private func calculateIdentifiers(_ leaves: [String: CBChatLeaf]? = nil) -> Set<CBChatIdentifier> {
        var identifiers = (leaves ?? self.leaves).values
            .reduce(into: Set<CBChatIdentifier>()) { identifiers, leaf in
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

public struct CBChatParticipant {
    public init?(dictionary: [AnyHashable: Any]) {}
}

extension CBChat {
    public var IMChats: [IMChat] {
        leaves.values.compactMap(\.IMChat)
    }
}

// MARK: - Message sending
extension IMChat {
    @MainActor public func send(message: IMMessage) {
        send(message)
    }

    public func send(message: IMMessageItem) async {
        await send(message: IMMessage(fromIMMessageItem: message, sender: nil, subject: nil))
    }

    public func send(message: CreateMessage) async throws -> IMMessage {
        let message = try message.imMessage(inChat: self)
        await send(message: message)
        return message
    }
}
