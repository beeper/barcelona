//
//  ERTimeSortedParticipantsManager.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/18/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import os.log

private let ManagerLog = OSLog(subsystem: "CoreBarcelona", category: "ParticipantsManager")

public struct ParticipantSortRule: Equatable, Hashable {
    var handleID: String
    var lastSentMessageTime: Double
    
    public func hash(into hasher: inout Hasher) {
        handleID.hash(into: &hasher)
    }
    
    public var hashValue: Int {
        handleID.hashValue
    }
    
    public static func ==(lhs: ParticipantSortRule, rhs: ParticipantSortRule) -> Bool {
        lhs.handleID == rhs.handleID
    }
}

protocol ERTimeSortedParticipantsManagerIngestible {
    var senderID: String? { get }
    var numberTime: Double? { get }
}

extension ERTimeSortedParticipantsManagerIngestible {
    var sortRule: ParticipantSortRule? {
        guard let handleID = senderID else {
            return nil
        }
        
        return ParticipantSortRule(handleID: handleID, lastSentMessageTime: numberTime ?? 0)
    }
}

extension IMItem: ERTimeSortedParticipantsManagerIngestible {
    var senderID: String? {
        self.sender
    }
    
    var numberTime: Double? {
        (self.time?.timeIntervalSince1970 ?? 0) * 1000
    }
}

extension IMMessage: ERTimeSortedParticipantsManagerIngestible {
    var senderID: String? {
        self.sender?.id
    }
    
    var numberTime: Double? {
        (self.time?.timeIntervalSince1970 ?? 0) * 1000
    }
}

extension IMMessageChatItem: ERTimeSortedParticipantsManagerIngestible {
    var senderID: String? {
        self.sender?.id
    }
    
    var numberTime: Double? {
        (self.time?.timeIntervalSince1970 ?? 0) * 1000
    }
}

extension Message: ERTimeSortedParticipantsManagerIngestible {
    var senderID: String? {
        self.sender
    }
    
    var numberTime: Double? {
        self.time
    }
}

private extension Array {
    func appending(_ element: Element) -> [Element] {
        var array = self
        array.append(element)
        return array
    }
}

private extension Notification {
    var chat: IMChat? {
        object as? IMChat ?? userInfo?["user"] as? IMChat
    }
}

extension NotificationCenter {
    func addObserver(forName: Notification.Name, using: @escaping (Notification) -> Void) {
        addObserver(forName: forName, object: nil, queue: nil, using: using)
    }
}

public class ERTimeSortedParticipantsManager {
    public static let sharedInstance = ERTimeSortedParticipantsManager()
    
    private init() {
        NotificationCenter.default.addObserver(forName: ERChatMessagesReceivedNotification) { notification in
            if let ingestible = notification.object as? [ERTimeSortedParticipantsManagerIngestible] {
                self.ingest(items: ingestible, inChat: notification.userInfo!["chat"] as! String)
            }
        }
        
        NotificationCenter.default.addObserver(forName: ERChatMessageReceivedNotification) { notification in
            if let ingestible = notification.object as? ERTimeSortedParticipantsManagerIngestible {
                self.ingest(item: ingestible, inChat: notification.userInfo!["chat"] as! String)
            }
        }
        
        NotificationCenter.default.addObserver(forName: .IMChatRegistryDidRegisterChat, using: ingest(bootstrapNotification:))
        
        NotificationCenter.default.addObserver(forName: .IMChatRegistryDidUnregisterChat, using: ingest(bootstrapNotification:))
        
        NotificationCenter.default.addObserver(forName: .IMChatParticipantsDidChange, using: ingest(bootstrapNotification:))
    }
    
    private func ingest(bootstrapNotification notification: Notification) {
        if let chat = notification.chat {
            os_log("Recomputing sorted participants with chat ID %@ per notification %@", log: ManagerLog, chat.id, notification.name.rawValue)
            self.bootstrap(chat: chat).whenSuccess {
                os_log("Finished recomputing sorted participants with chat ID %@ per notification %@", log: ManagerLog, chat.id, notification.name.rawValue)
            }
        }
    }
    
    var chatToParticipantSortRules: [String: [ParticipantSortRule]] = [:]
    
    public func sortedParticipants(forChat chat: String) -> [String] {
        chatToParticipantSortRules[chat]?.map { $0.handleID } ?? []
    }
    
    public func ingest(item: IMItem, inChat chat: String) {
        self.ingest(item: item as ERTimeSortedParticipantsManagerIngestible, inChat: chat)
    }
    
    public func ingest(item: IMMessageItem, inChat chat: String) {
        self.ingest(item: item as ERTimeSortedParticipantsManagerIngestible, inChat: chat)
    }
    
    public func ingest(item: IMMessage, inChat chat: String) {
        self.ingest(item: item as ERTimeSortedParticipantsManagerIngestible, inChat: chat)
    }
    
    func ingest(item: ERTimeSortedParticipantsManagerIngestible, inChat chat: String) {
        guard let sortRule = item.sortRule else {
            return
        }
        
        self.ingest(rule: sortRule, inChat: chat)
    }
    
    func ingest(items: [ERTimeSortedParticipantsManagerIngestible], inChat chat: String) {
        var rules = items.compactMap {
            $0.sortRule
        }
        
        rules.sort { r1, r2 in
            r1.lastSentMessageTime > r2.lastSentMessageTime
        }
        
        rules = rules.removingDuplicates()
        
        rules.forEach {
            self.ingest(rule: $0, inChat: chat)
        }
    }
    
    func ingest(rule: ParticipantSortRule, inChat chat: String) {
        if chatToParticipantSortRules[chat] == nil {
            return
        }
        
        chatToParticipantSortRules[chat] = chatToParticipantSortRules[chat]!.filter {
            $0.handleID != rule.handleID ? true : $0.lastSentMessageTime > rule.lastSentMessageTime
        }.appending(rule)
        
        self.sortParticipants(forChat: chat)
    }
    
    private func sortParticipants(forChat chat: String) {
        self.chatToParticipantSortRules[chat]?.sort(by: { r1, r2 in
            r1.lastSentMessageTime > r2.lastSentMessageTime
        })
    }
    
    public func unload(chatID: String) {
        self.chatToParticipantSortRules[chatID] = nil
    }
    
    public func bootstrap(chat: IMChat) -> Promise<Void, Error> {
        bootstrap(chats: [chat])
    }
    
    public func bootstrap(chats: [IMChat]) -> Promise<Void, Error> {
        DBReader.shared.handleTimestampRecords(forChatIdentifiers: chats.compactMap { $0.chatIdentifier }).then { records in
            self.chatToParticipantSortRules = records.reduce(into: [String: [ParticipantSortRule]]()) { ledger, record in
                if ledger[record.chat_id] == nil {
                    ledger[record.chat_id] = []
                }
                
                ledger[record.chat_id]!.append(ParticipantSortRule(handleID: record.handle_id, lastSentMessageTime: Date.timeIntervalSince1970FromIMDBDateValue(date: Double(record.date))))
            }
            
            self.chatToParticipantSortRules.keys.forEach { key in
                self.sortParticipants(forChat: key)
            }
        }
    }
}
