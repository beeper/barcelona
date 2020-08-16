//
//  ChatEvents.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/9/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import os.log

private let log_chatEvents = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "ChatEvents")

private let IMChatParticipantsDidChangeNotification = Notification.Name(rawValue: "__kIMChatParticipantsDidChangeNotification")
private let IMChatDisplayNameChangedNotification = Notification.Name(rawValue: "__kIMChatDisplayNameChangedNotification")
private let IMChatJoinStateDidChangeNotification = Notification.Name(rawValue: "__kIMChatJoinStateDidChangeNotification")
private let IMChatRegistryDidUnregisterChatNotification = Notification.Name(rawValue: "__kIMChatRegistryDidUnregisterChatNotification")
private let IMChatRegistryDidRegisterChatNotification = Notification.Name(rawValue: "__kIMChatRegistryDidRegisterChatNotification")

/**
 Events related to IMChat
 */
class ChatEvents: EventDispatcher {
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
    }
    
    // MARK: - IMChat created
    private func chatWasCreated(_ notification: Notification) {
        guard let chat = notification.object as? IMChat else {
            os_log("⁉️ got chat created notification but didn't receive IMChat in notification object", type: .error, log_chatEvents)
            return
        }
        
        StreamingAPI.shared.dispatch(eventFor(conversationCreated: chat.representation), to: nil)
    }
    
    // MARK: - IMChat deleted
    private func chatWasRemoved(_ notification: Notification) {
        guard let chatID = notification.object as? String else {
            os_log("⁉️ got chat removed notification but didn't receive NSString in notification object", type: .error, log_chatEvents)
            return
        }
        
        StreamingAPI.shared.dispatch(eventFor(conversationRemoved: ChatIDRepresentation(chat: chatID)), to: nil)
    }
    
    // MARK: - IMChat Participants changed
    private func participantsChanged(_ notification: Notification) {
        guard let chat = notification.object as? IMChat else {
            os_log("⁉️ got participants changed notification but didn't receive IMChat in notification object", type: .error, log_chatEvents)
            return
        }
        
        StreamingAPI.shared.dispatch(eventFor(participantsChanged: chat.participantHandleIDs(), in: chat.guid), to: nil)
    }
    
    // MARK: - IMChat Displayname changed
    private func chatDisplayNameChanged(_ notification: Notification) {
        guard let chat = notification.object as? IMChat else {
            os_log("⁉️ got chat display name changed notification but didn't receive IMChat in notification object", type: .error, log_chatEvents)
            return
        }
        
        StreamingAPI.shared.dispatch(eventFor(conversationDisplayNameChanged: chat.representation), to: nil)
    }
    
    // MARK: - IMChat join state changed
    private func chatJoinStateChanged(_ notification: Notification) {
        guard let chat = notification.object as? IMChat else {
            os_log("⁉️ got chat join state changed notification but didn't receive IMChat in notification object", type: .error, log_chatEvents)
            return
        }
        
        StreamingAPI.shared.dispatch(eventFor(conversationJoinStateChanged: chat.representation), to: nil)
    }
    
    private func chatDidRefresh(_ notification: Notification) {
        print(notification)
    }
}
