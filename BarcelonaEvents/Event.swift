//
//  Event.swift
//  imessage-rest
//
//  Created by Eric Rabil on 8/12/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import Barcelona
import IMCore

// MARK: - Event structure
public enum Event {
    case bootstrap(BootstrapData)
    case itemsReceived([AnyChatItem])
    case itemsUpdated([AnyChatItem])
    case itemStatusChanged(StatusChatItem)
    /// Contains the IDs of the removed items
    case itemsRemoved([String])
    case participantsChanged(ParticipantChangeRecord)
    /// Contains the ID of the removed chat
    case conversationRemoved(String)
    case conversationCreated(Chat)
    case conversationChanged(Chat)
    case conversationDisplayNameChanged(Chat)
    case conversationJoinStateChanged(Chat)
    case conversationUnreadCountChanged(Chat)
    case conversationPropertiesChanged(ChatConfigurationRepresentation)
    case contactCreated(Contact)
    /// Contains the ID of the removed contact
    case contactRemoved(String)
    case contactUpdated(Contact)
    case blockListUpdated(BulkHandleIDRepresentation)
    case healthChanged(HealthState)
}

public struct BootstrapData: Codable, Hashable, BulkChatRepresentatable {
    public struct BootstrapOptions {
        var chatLimit: Int?
        var contactLimit: Int?
        
        public init() {
            chatLimit = 0
            contactLimit = 0
        }
    }
    
    public init(_ options: BootstrapOptions = BootstrapOptions(), limitChats: Int? = nil) {
        chats = IMChatRegistry.shared.allSortedChats(limit: limitChats ?? options.chatLimit)
        contacts = IMContactStore.shared.representations()
        totalChats = IMChatRegistry.shared.allChats.count
    }
    
    public var chats: [Chat]
    public var totalChats: Int
    public var contacts: BulkContactRepresentation
    public var messages: [Message]?
}

// MARK: - Participant events
public struct ParticipantChangeRecord: Codable, Hashable, BulkHandleIDRepresentable {
    public var chat: String
    public var handles: [String]
}

public struct HealthState: Codable, Hashable {
    public var authenticationState: HealthChecker.AuthenticationState
    public var connectionState: HealthChecker.ConnectionState
}
