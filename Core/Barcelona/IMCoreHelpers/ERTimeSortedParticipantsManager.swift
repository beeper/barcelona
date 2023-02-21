//
//  ERTimeSortedParticipantsManager.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/18/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import BarcelonaDB
import Combine
import Foundation
import IMCore
import IMSharedUtilities
import Logging

private let log = Logger(label: "ParticipantsManager")

public struct ParticipantSortRule: Equatable, Hashable {
    var handleID: String
    var lastSentMessageTime: Double

    public func hash(into hasher: inout Hasher) {
        handleID.hash(into: &hasher)
    }

    public var hashValue: Int {
        handleID.hashValue
    }

    public static func == (lhs: ParticipantSortRule, rhs: ParticipantSortRule) -> Bool {
        lhs.handleID == rhs.handleID
    }
}

public protocol ERTimeSortedParticipantsManagerIngestible {
    var senderID: String? { get }
    var effectiveTime: Double { get }
}

extension ERTimeSortedParticipantsManagerIngestible {
    var sortRule: ParticipantSortRule? {
        guard let handleID = senderID else {
            return nil
        }

        return ParticipantSortRule(handleID: handleID, lastSentMessageTime: effectiveTime)
    }
}

extension ERTimeSortedParticipantsManagerIngestible {
    fileprivate var bestHandleIDForMe: String? {
        Registry.sharedInstance.uniqueMeHandleIDs.first
    }
}

extension IMItem: ERTimeSortedParticipantsManagerIngestible {
    public var senderID: String? {
        resolveSenderID(inService: serviceStyle) ?? (isFromMe ? bestHandleIDForMe : nil)
    }

    public var effectiveTime: Double {
        (self.time?.timeIntervalSince1970 ?? 0) * 1000
    }
}

extension IMMessage: ERTimeSortedParticipantsManagerIngestible {
    public var senderID: String? {
        resolveSenderID(inService: _imMessageItem?.serviceStyle) ?? (isFromMe ? bestHandleIDForMe : nil)
    }

    public var effectiveTime: Double {
        (self.time?.timeIntervalSince1970 ?? 0) * 1000
    }
}

extension IMTranscriptChatItem {
    private var reliableDate: Date? {
        switch self {
        case let item as IMMessageChatItem:
            return item.time ?? _item()?.time
        default:
            return transcriptDate ?? _item()?.time
        }
    }

    public var effectiveTime: Double {
        (reliableDate?.timeIntervalSince1970 ?? 0) * 1000
    }
}

extension Message: ERTimeSortedParticipantsManagerIngestible {
    public var senderID: String? {
        self.sender ?? (fromMe ? bestHandleIDForMe : nil)
    }

    public var effectiveTime: Double {
        self.time
    }
}

extension Array {
    fileprivate func appending(_ element: Element) -> [Element] {
        var array = self
        array.append(element)
        return array
    }
}

extension Notification {
    fileprivate var chat: IMChat? {
        object as? IMChat ?? userInfo?["user"] as? IMChat
    }
}

extension NotificationCenter {
    func addObserver(forName: Notification.Name, using: @escaping (Notification) -> Void) {
        addObserver(forName: forName, object: nil, queue: nil, using: using)
    }
}

public class ERTimeSortedParticipantsManager {

    // MARK: - Properties

    public static let sharedInstance = ERTimeSortedParticipantsManager()

    private let lock = NSRecursiveLock()

    private var chatToParticipantSortRules: [String: [ParticipantSortRule]] = [:]

    // MARK: - Initializers

    private init() {
        Task {
            await listen()
        }
    }

    // MARK: - Methods

    public func sortedParticipants(forChat chat: String) -> [String] {
        lock.lock()
        defer {
            lock.unlock()
        }
        return chatToParticipantSortRules[chat]?.map(\.handleID) ?? []
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

    public func unload(chatID: String) {
        lock.lock()
        defer {
            lock.unlock()
        }
        self.chatToParticipantSortRules[chatID] = nil
    }

    public func bootstrap(chat: IMChat) throws {
        try bootstrap(chats: [chat])
    }

    public func bootstrap(chats: [IMChat]) throws {
        lock.lock()
        defer {
            lock.unlock()
        }
        let records = try DBReader.shared.handleTimestampRecords(
            forChatIdentifiers: chats.compactMap { $0.chatIdentifier }
        )
        chatToParticipantSortRules =
            records.map { record in
                (
                    record.chat_id,
                    ParticipantSortRule(
                        handleID: record.handle_id,
                        lastSentMessageTime: Date.timeIntervalSince1970FromIMDBDateValue(date: Double(record.date))
                    )
                )
            }
            .collectedDictionary(keyedBy: \.0, valuedBy: \.1)

        for (chat, _) in chatToParticipantSortRules {
            sortParticipants(forChat: chat)
        }
    }

    private func listen() async {
        NotificationCenter.default.publisher(for: ERChatMessagesReceivedNotification)
            .merge(with: NotificationCenter.default.publisher(for: ERChatMessageReceivedNotification))
            .sink { [unowned self] notification in
                if let ingestible = notification.object as? [ERTimeSortedParticipantsManagerIngestible] {
                    ingest(items: ingestible, inChat: notification.userInfo!["chat"] as! String)
                }
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .IMChatRegistryDidRegisterChat)
            .merge(
                with: NotificationCenter.default.publisher(for: .IMChatRegistryDidUnregisterChat),
                NotificationCenter.default.publisher(for: .IMChatParticipantsDidChange)
            )
            .sink { [unowned self] notification in
                ingest(bootstrapNotification: notification)
            }
            .store(in: &cancellables)
    }

    private func ingest(bootstrapNotification notification: Notification) {
        if let chat = notification.chat {
            do {
                log.info(
                    "Recomputing sorted participants with chat ID \(chat.id) per notification \(notification.name.rawValue)"
                )
                try bootstrap(chat: chat)
                log.info(
                    "Finished recomputing sorted participants with chat ID \(chat.id) per notification \(notification.name.rawValue)"
                )
            } catch {
                log.error("Error ")
            }
        }
    }

    private func sortParticipants(forChat chat: String) {
        lock.lock()
        defer {
            lock.unlock()
        }
        self.chatToParticipantSortRules[chat]?
            .sort(by: { r1, r2 in
                r1.lastSentMessageTime > r2.lastSentMessageTime
            })
    }

    private func ingest(item: ERTimeSortedParticipantsManagerIngestible, inChat chat: String) {
        guard let sortRule = item.sortRule else {
            return
        }

        self.ingest(rule: sortRule, inChat: chat)
    }

    private func ingest(items: [ERTimeSortedParticipantsManagerIngestible], inChat chat: String) {
        var rules = items.compactMap(\.sortRule)

        rules.sort { r1, r2 in
            r1.lastSentMessageTime > r2.lastSentMessageTime
        }

        rules = rules.removingDuplicates()

        rules.forEach {
            self.ingest(rule: $0, inChat: chat)
        }
    }

    private func ingest(rule: ParticipantSortRule, inChat chat: String) {
        lock.lock()
        defer {
            lock.unlock()
        }
        if chatToParticipantSortRules[chat] == nil {
            return
        }

        chatToParticipantSortRules[chat] = chatToParticipantSortRules[chat]!
            .filter {
                $0.handleID != rule.handleID ? true : $0.lastSentMessageTime > rule.lastSentMessageTime
            }
            .appending(rule)

        self.sortParticipants(forChat: chat)
    }

    private var cancellables = Set<AnyCancellable>()
}
