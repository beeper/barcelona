//
//  ChatEvents.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/9/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import CoreBarcelona
import IMCore
import os.log

private let log_chatEvents = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "ChatEvents")

private let IMChatParticipantsDidChangeNotification = Notification.Name(rawValue: "__kIMChatParticipantsDidChangeNotification")
private let IMChatDisplayNameChangedNotification = Notification.Name(rawValue: "__kIMChatDisplayNameChangedNotification")
private let IMChatJoinStateDidChangeNotification = Notification.Name(rawValue: "__kIMChatJoinStateDidChangeNotification")
private let IMChatRegistryDidUnregisterChatNotification = Notification.Name(rawValue: "__kIMChatRegistryDidUnregisterChatNotification")
private let IMChatRegistryDidRegisterChatNotification = Notification.Name(rawValue: "__kIMChatRegistryDidRegisterChatNotification")
private let IMChatUnreadCountChangedNotification = Notification.Name(rawValue: "__kIMChatUnreadCountChangedNotification")
private let IMChatPropertiesChangedNotification = Notification.Name(rawValue: "__kIMChatPropertiesChangedNotification")

struct ChatUnreadCountRepresentation: Codable {
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
class ChatEvents: EventDispatcher {
    private let debouncer = CategorizedDebounceManager<ChatDebounceCategory>([
        .chatProperties: Double(1 / 10),
        .unreadCount: Double(1 / 5)
    ])
    
    override func wake() {
        addObserver(forName: IMChatParticipantsDidChangeNotification) {
            self.participantsChanged($0)
        }
        
        addObserver(forName: IMChatDisplayNameChangedNotification) {
            self.chatDisplayNameChanged($0)
        }
        
        addObserver(forName: IMChatJoinStateDidChangeNotification) {
            self.chatJoinStateChanged($0)
        }
        
        addObserver(forName: IMChatRegistryDidUnregisterChatNotification) {
            self.chatWasRemoved($0)
        }
        
        addObserver(forName: IMChatRegistryDidRegisterChatNotification) {
            self.chatWasCreated($0)
        }
        
        addObserver(forName: IMChatUnreadCountChangedNotification) {
            self.unreadCountChanged($0)
        }
        
        addObserver(forName: IMChatPropertiesChangedNotification) {
            self.chatPropertiesChanged($0)
        }
    }
    
    private func chatPropertiesChanged(_ notification: Notification) {
        guard let chat = notification.object as? IMChat else {
            os_log("⁉️ got chat properties notification but didn't receive IMChat in notification object", type: .error, log_chatEvents)
            return
        }
        
        debouncer.submit(chat.id, category: .chatProperties) {
            StreamingAPI.shared.dispatch(eventFor(conversationPropertiesChanged: chat.properties))
        }
    }
    
    private func unreadCountChanged(_ notification: Notification) {
        guard let chat = notification.object as? IMChat else {
            os_log("⁉️ got chat unread notification but didn't receive IMChat in notification object", type: .error, log_chatEvents)
            return
        }
        
        debouncer.submit(chat.id, category: .unreadCount) {
            StreamingAPI.shared.dispatch(eventFor(conversationUnreadCountChanged: chat.representation))
        }
    }
    
    // MARK: - IMChat created
    private func chatWasCreated(_ notification: Notification) {
        guard let chat = notification.object as? IMChat else {
            os_log("⁉️ got chat created notification but didn't receive IMChat in notification object", type: .error, log_chatEvents)
            return
        }
        
        ERTimeSortedParticipantsManager.sharedInstance.bootstrap(chat: chat).whenSuccess {
            StreamingAPI.shared.dispatch(eventFor(conversationCreated: chat.representation), to: nil)
        }
    }
    
    // MARK: - IMChat deleted
    private func chatWasRemoved(_ notification: Notification) {
        guard let chatID = notification.object as? String else {
            os_log("⁉️ got chat removed notification but didn't receive NSString in notification object", type: .error, log_chatEvents)
            return
        }
        
        ERTimeSortedParticipantsManager.sharedInstance.unload(chatID: chatID)
        
        StreamingAPI.shared.dispatch(eventFor(conversationRemoved: ChatIDRepresentation(chat: chatID)), to: nil)
    }
    
    // MARK: - IMChat Participants changed
    private func participantsChanged(_ notification: Notification) {
        guard let chat = notification.object as? IMChat else {
            os_log("⁉️ got participants changed notification but didn't receive IMChat in notification object", type: .error, log_chatEvents)
            return
        }
        
        chat.scheduleForReview()
        
        StreamingAPI.shared.dispatch(eventFor(participantsChanged: chat.participantHandleIDs(), in: chat.id), to: nil)
    }
    
    // MARK: - IMChat Displayname changed
    private func chatDisplayNameChanged(_ notification: Notification) {
        guard let chat = notification.object as? IMChat else {
            os_log("⁉️ got chat display name changed notification but didn't receive IMChat in notification object", type: .error, log_chatEvents)
            return
        }
        
        chat.scheduleForReview()
        
        StreamingAPI.shared.dispatch(eventFor(conversationDisplayNameChanged: chat.representation), to: nil)
    }
    
    // MARK: - IMChat join state changed
    private func chatJoinStateChanged(_ notification: Notification) {
        guard let chat = notification.object as? IMChat else {
            os_log("⁉️ got chat join state changed notification but didn't receive IMChat in notification object", type: .error, log_chatEvents)
            return
        }
        
        chat.scheduleForReview()
        
        StreamingAPI.shared.dispatch(eventFor(conversationJoinStateChanged: chat.representation), to: nil)
    }
    
    private func chatDidRefresh(_ notification: Notification) {
        print(notification)
    }
}
