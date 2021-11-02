//
//  ChatEvents.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/9/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import BarcelonaFoundation
import Barcelona
import IMCore

private let IMChatUnreadCountChangedNotification = Notification.Name(rawValue: "__kIMChatUnreadCountChangedNotification")

public struct ChatUnreadCountRepresentation: Codable {
    var chatID: String
    var unread: Int
}

private enum ChatDebounceCategory {
    case chatProperties
    case unreadCount
}

/**
 Events related to IMChat
 */
public class ChatEvents: EventDispatcher {
    override var log: Logger { Logger(category: "ChatEvents") }
    
    private let debouncer = CategorizedDebounceManager<ChatDebounceCategory>([
        .chatProperties: Double(1 / 10),
        .unreadCount: Double(1 / 5)
    ])
    
    public override func wake() {
        addObserver(forName: .IMChatParticipantsDidChange) {
            self.participantsChanged($0)
        }
        
//        addObserver(forName: .IMChatDisplayNameChanged) {
//            self.chatDisplayNameChanged($0)
//        }
        
        addObserver(forName: .IMChatJoinStateDidChange) {
            self.chatJoinStateChanged($0)
        }
        
        addObserver(forName: .IMChatRegistryDidUnregisterChat) {
            self.chatWasRemoved($0)
        }
        
        addObserver(forName: .IMChatRegistryDidRegisterChat) {
            self.chatWasCreated($0)
        }
        
        addObserver(forName: IMChatUnreadCountChangedNotification) {
            self.unreadCountChanged($0)
        }
        
        addObserver(forName: .IMChatPropertiesChanged) {
            self.chatPropertiesChanged($0)
        }
        
        addObserver(forName: .init("__k_IMHandleCommandReceivedNotification")) { notification in
            CLDebug("ChatEvents", "Received IMHandleCommandReceivedNotification %@", notification)
        }
    }
    
    private func chatPropertiesChanged(_ notification: Notification) {
        guard let chat = notification.object as? IMChat else {
            log.error("⁉️ got chat properties notification but didn't receive IMChat in notification object")
            return
        }
        
        debouncer.submit(chat.id, category: .chatProperties) {
            self.bus.dispatch(.conversationPropertiesChanged(chat.configurationBits))
        }
    }
    
    private func unreadCountChanged(_ notification: Notification) {
        guard let chat = notification.object as? IMChat else {
            log.error("⁉️ got chat unread notification but didn't receive IMChat in notification object")
            return
        }
        
        debouncer.submit(chat.id, category: .unreadCount) {
            self.bus.dispatch(.conversationUnreadCountChanged(Chat(chat)))
        }
    }
    
    // MARK: - IMChat created
    private func chatWasCreated(_ notification: Notification) {
        guard let chat = notification.object as? IMChat else {
            log.error("⁉️ got chat created notification but didn't receive IMChat in notification object")
            return
        }
        
        ERTimeSortedParticipantsManager.sharedInstance.bootstrap(chat: chat).then {
            self.bus.dispatch(.conversationCreated(Chat(chat)))
        }
    }
    
    // MARK: - IMChat deleted
    private func chatWasRemoved(_ notification: Notification) {
        guard let chatID = notification.object as? String else {
            log.error("⁉️ got chat removed notification but didn't receive NSString in notification object")
            return
        }
        
        ERTimeSortedParticipantsManager.sharedInstance.unload(chatID: chatID)
        
        bus.dispatch(.conversationRemoved(chatID))
    }
    
    // MARK: - IMChat Participants changed
    private func participantsChanged(_ notification: Notification) {
        guard let chat = notification.object as? IMChat else {
            log.error("⁉️ got participants changed notification but didn't receive IMChat in notification object")
            return
        }
        
        chat.scheduleForReview()
        
        bus.dispatch(.participantsChanged(ParticipantChangeRecord(chat: chat.id, handles: chat.participantHandleIDs())))
    }
    
    // MARK: - IMChat Displayname changed
    private func chatDisplayNameChanged(_ notification: Notification) {
        guard let chat = notification.object as? IMChat else {
            log.error("⁉️ got chat display name changed notification but didn't receive IMChat in notification object")
            return
        }
        
        chat.scheduleForReview()
        
        bus.dispatch(.conversationDisplayNameChanged(Chat(chat)))
    }
    
    // MARK: - IMChat join state changed
    private func chatJoinStateChanged(_ notification: Notification) {
        guard let chat = notification.object as? IMChat else {
            log.error("⁉️ got chat join state changed notification but didn't receive IMChat in notification object")
            return
        }
        
        chat.scheduleForReview()
        
        bus.dispatch(.conversationJoinStateChanged(Chat(chat)))
    }
    
    private func chatDidRefresh(_ notification: Notification) {
        CLDebug("ChatEvents", "chat did refresh %@", notification)
    }
}
