//
//  Event.swift
//  imessage-rest
//
//  Created by Eric Rabil on 8/12/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import CoreBarcelona
import NIO

// MARK: - Event structure
struct Event<P: Codable>: Codable {
    public let type: Event.EventType
    public let data: P?
    
    enum EventType: String, Codable {
        case bootstrap
        case itemsReceived
        case itemsUpdated
        case itemStatusChanged
        case itemsRemoved
        case participantsChanged
        case conversationRemoved
        case conversationCreated
        case conversationChanged
        case conversationDisplayNameChanged
        case conversationJoinStateChanged
        case conversationUnreadCountChanged
        case conversationPropertiesChanged
        case contactCreated
        case contactRemoved
        case contactUpdated
        case blockListUpdated
    }
}

internal let eventProcessing_eventLoop = MultiThreadedEventLoopGroup(numberOfThreads: 3)

// MARK: - Event generators

func eventFor(bootstrap: BootstrapData) -> Event<BootstrapData> {
    return Event<BootstrapData>(type: .bootstrap, data: bootstrap)
}

// MARK: - Item events
func eventFor(itemsReceived: BulkChatItemRepresentation) -> Event<BulkChatItemRepresentation> {
    return Event<BulkChatItemRepresentation>(type: .itemsReceived, data: itemsReceived)
}

func eventFor(itemsUpdated: BulkChatItemRepresentation) -> Event<BulkChatItemRepresentation> {
    return Event<BulkChatItemRepresentation>(type: .itemsUpdated, data: itemsUpdated)
}

func eventFor(itemStatusChanged: StatusChatItem) -> Event<StatusChatItem> {
    return Event<StatusChatItem>(type: .itemStatusChanged, data: itemStatusChanged)
}

func eventFor(itemsRemoved: BulkMessageIDRepresentation) -> Event<BulkMessageIDRepresentation> {
    return Event<BulkMessageIDRepresentation>(type: .itemsRemoved, data: itemsRemoved)
}

// MARK: - Participant events
struct ParticipantChangeRecord: Codable, BulkHandleIDRepresentable {
    var chat: String
    var handles: [String]
}

func eventFor(participantsChanged: [String], in chat: String) -> Event<ParticipantChangeRecord> {
    return Event<ParticipantChangeRecord>(type: .participantsChanged, data: ParticipantChangeRecord(chat: chat, handles: participantsChanged))
}

// MARK: - Chat events
func eventFor(conversationRemoved: ChatIDRepresentation) -> Event<ChatIDRepresentation> {
    return Event<ChatIDRepresentation>(type: .conversationRemoved, data: conversationRemoved)
}

func eventFor(conversationCreated: Chat) -> Event<Chat> {
    return Event<Chat>(type: .conversationCreated, data: conversationCreated)
}

func eventFor(conversationChanged: Chat) -> Event<Chat> {
    return Event<Chat>(type: .conversationChanged, data: conversationChanged)
}

func eventFor(conversationDisplayNameChanged: Chat) -> Event<Chat> {
    return Event<Chat>(type: .conversationDisplayNameChanged, data: conversationDisplayNameChanged)
}

func eventFor(conversationJoinStateChanged: Chat) -> Event<Chat> {
    return Event<Chat>(type: .conversationJoinStateChanged, data: conversationJoinStateChanged)
}

func eventFor(conversationUnreadCountChanged: Chat) -> Event<Chat> {
    return Event<Chat>(type: .conversationUnreadCountChanged, data: conversationUnreadCountChanged)
}

func eventFor(conversationPropertiesChanged: ChatConfigurationRepresentation) -> Event<ChatConfigurationRepresentation> {
    return Event<ChatConfigurationRepresentation>(type: .conversationPropertiesChanged, data: conversationPropertiesChanged)
}

// MARK: - Contact events
func eventFor(contactCreated: Contact) -> Event<Contact> {
    return Event<Contact>(type: .contactCreated, data: contactCreated)
}

func eventFor(contactRemoved: ContactIDRepresentation) -> Event<ContactIDRepresentation> {
    return Event<ContactIDRepresentation>(type: .contactRemoved, data: contactRemoved)
}

func eventFor(contactUpdated: Contact) -> Event<Contact> {
    return Event<Contact>(type: .contactUpdated, data: contactUpdated)
}

// MARK: - Blocklist Events
func eventFor(blockListUpdated: BulkHandleIDRepresentation) -> Event<BulkHandleIDRepresentation> {
    return Event<BulkHandleIDRepresentation>(type: .blockListUpdated, data: blockListUpdated)
}
