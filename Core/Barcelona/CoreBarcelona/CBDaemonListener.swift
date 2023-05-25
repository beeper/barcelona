//
//  ERDaemonListener.swift
//  imessage-rest
//
//  Created by Eric Rabil on 8/11/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//
//  CBDaemonListener is the new publisher for iMessage events. It is synchronous and does very minimal post-processing.
//
//  It does away with most foundation APIs, opting for a much more lightweight pipeline that acts as a delivery mechanism to higher-level implementations.
//

import BarcelonaDB
import Combine
import CommunicationsFilter
import Foundation
import IMCore
import IMDMessageServices
import IMDaemonCore
import IMFoundation
import IMSharedUtilities
import Logging

private let log = Logger(label: "ERDaemonListener")

extension String {
    fileprivate var bl_mergedID: String {
        if let lastIndex = lastIndex(of: ";") {
            return String(self[index(after: lastIndex)...])
        }

        return self
    }
}

extension IMItem {
    fileprivate var nonce: Int {
        var hasher = Hasher()
        id.hash(into: &hasher)
        type.hash(into: &hasher)
        isFromMe.hash(into: &hasher)

        switch self {
        case let item as IMMessageItem:
            item.body?.hash(into: &hasher)
            item.messageID.hash(into: &hasher)
            item.associatedMessageGUID()?.hash(into: &hasher)
        default:
            break
        }

        return hasher.finalize()
    }
}

public enum CBMessageStatusType: String, Codable {
    case delivered
    case read
    case played
    case downgraded
    case notDelivered
    case sent
}

private struct CBMessageStatusChangeContext {
    var message: IMMessageItem?
}

// Represents the different updates that are made to a message
public struct CBMessageStatusChange: Codable, Hashable {
    public static func == (lhs: CBMessageStatusChange, rhs: CBMessageStatusChange) -> Bool {
        false
    }

    fileprivate init(
        type: CBMessageStatusType,
        service: IMServiceStyle,
        time: Double,
        sender: String? = nil,
        fromMe: Bool,
        chatID: String,
        messageID: String,
        context: CBMessageStatusChangeContext = .init()
    ) {
        self.type = type
        self.service = service
        self.time = time
        self.sender = sender
        self.fromMe = fromMe
        self.chatID = chatID
        self.messageID = messageID
        self.context = context
    }

    public var type: CBMessageStatusType
    public var service: IMServiceStyle
    public var time: Double
    public var sender: String?
    public var fromMe: Bool
    public var chatID: String
    public var messageID: String

    // backing storage for the message object used to create this
    private var context: CBMessageStatusChangeContext = .init()

    public var chat: IMChat? {
        IMChat.chat(withIdentifier: chatID, onService: service)
    }

    public var hasFullMessage: Bool {
        context.message != nil
    }

    public var message: IMMessageItem {
        context.message ?? IMMessageItem()
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(service)
        hasher.combine(time)
        hasher.combine(sender)
        hasher.combine(fromMe)
        hasher.combine(chatID)
        hasher.combine(messageID)
    }

    private enum CodingKeys: String, CodingKey {
        case type, service, time, sender, fromMe, chatID, messageID
    }
}

extension Notification.Name: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        self.init(rawValue: value)
    }
}

extension CBDaemonListener {
}

class OrderedDictionary<K: Hashable, V> {
    private(set) var dictionary: [K: V] = [:]
    private var orderedSet: NSMutableOrderedSet = .init()

    var maximumCapacity: Int? = nil

    init() {}

    init(maximumCapacity: Int) {
        self.maximumCapacity = maximumCapacity
    }

    subscript(_ key: K) -> V? {
        get {
            let index = orderedSet.index(of: key)
            if index != NSNotFound {
                orderedSet.moveObjects(at: IndexSet(integer: index), to: orderedSet.count - 1)
            }
            return dictionary[key]
        }
        set {
            if newValue == nil {
                orderedSet.remove(key)
                dictionary.removeValue(forKey: key)
            } else {
                let index = orderedSet.index(of: key)
                if index == NSNotFound {
                    orderedSet.add(key)
                    if let maximumCapacity = maximumCapacity, orderedSet.count == maximumCapacity,
                        let first = orderedSet.firstObject
                    {
                        orderedSet.remove(first)
                        dictionary.removeValue(forKey: first as! K)
                    }
                } else {
                    orderedSet.moveObjects(at: IndexSet(integer: index), to: orderedSet.count - 1)
                }
                dictionary[key] = newValue
            }
        }
    }
}

public class CBDaemonListener: ERBaseDaemonListener {
    public static let shared = CBDaemonListener()

    public let unreadCountPipeline = PassthroughSubject<(chat: String, count: Int), Never>()
    public let typingPipeline = PassthroughSubject<(chat: String, service: IMServiceStyle, typing: Bool), Never>()
    public let chatNamePipeline = PassthroughSubject<(chat: String, name: String?), Never>()
    public let blocklistPipeline = PassthroughSubject<[String], Never>()
    public let messagesDeletedPipeline = PassthroughSubject<[String], Never>()
    public let chatsDeletedPipeline = PassthroughSubject<[String], Never>()
    public let chatJoinStatePipeline = PassthroughSubject<(chat: String, joinState: IMChatJoinState), Never>()
    public let messagePipeline = PassthroughSubject<Message, Never>()
    public let phantomPipeline = PassthroughSubject<PhantomChatItem, Never>()
    public let messageStatusPipeline = PassthroughSubject<CBMessageStatusChange, Never>()
    public let disconnectPipeline = NotificationCenter.default.publisher(for: .IMDaemonDidDisconnect)

    private override init() {
        super.init()
    }

    // Caches for determining whether an update notification is needed
    private var unreadCounts: [String: Int] = [:]
    private var displayNames: [String: String] = [:]
    private var participants: [String: [String]] = [:]

    private var currentlyTyping = Set<String>()

    // Dedupes messages sent from self - we should have a cleanup routine for this
    private var nonces = Set<Int>()

    private var bag = Set<AnyCancellable>()

    private lazy var listenForDisconnectsOnce: AnyCancellable = {
        disconnectPipeline.sink { _ in self.disconnectedFromDaemon() }
    }()

    /// In the event a reflected read receipt is processed immediately before an SMS relay message, it will die. This buffer tracks the n most recent GUIDs, which should support this edge case.
    internal private(set) var smsReadBuffer: [String] = []
    internal var smsReadBufferCapacity: Int = 15 {
        didSet {
            smsReadBuffer = smsReadBuffer.suffix(smsReadBufferCapacity)
        }
    }

    private var chatIdentifierCache = OrderedDictionary<String, String>(maximumCapacity: 100)

    private func disconnectedFromDaemon() {
        log.warning("Disconnected from daemon, reconnecting.")

        IMDaemonController.shared()
            .connectToDaemon(
                withLaunch: true,
                capabilities: FZListenerCapabilities.defaults_,
                blockUntilConnected: true
            )
        IMDaemonController.shared().listener.addHandler(self)
    }

    public override func setupComplete(_ success: Bool, info: [AnyHashable: Any]!) {
        _ = listenForDisconnectsOnce  // workaround for swift murdering dispatch_once because apple

        log.debug("setup: \(success)")

        if let info = info, let dicts = (info["personMergedChats"] ?? info["chats"]) as? [[AnyHashable: Any]] {
            for dict in dicts {
                apply(serializedChat: dict, emitIfNeeded: false)
            }
        }

        DispatchQueue.global(qos: .background)
            .async {
                for chat in IMChatRegistry.shared.allChats {
                    _ = chat.chatItemRules
                }
            }

        guard ProcessInfo.processInfo.environment["BLNoBlocklist"] == nil else {
            return
        }

        ERSharedBlockList()._connect()
    }

    static var didStartListening = false

    public func startListening() async {
        guard CBDaemonListener.didStartListening == false else {
            return
        }

        CBDaemonListener.didStartListening = true

        _ = CBIDSListener.shared.reflectedReadReceiptPipeline.sink { guid, service, time in
            Task {
                let chatIdentifier = try? await DBReader.shared.chatIdentifier(forMessageGUID: guid)

                log.debug(
                    "reflectedReadReceiptPipeline received guid \(guid) in chat \(String(describing: chatIdentifier))"
                )

                guard let chatIdentifier else {
                    return
                }

                self.messageStatusPipeline.send(
                    CBMessageStatusChange(
                        type: .read,
                        service: service,
                        time: time.timeIntervalSince1970,
                        fromMe: true,
                        chatID: chatIdentifier,
                        messageID: guid
                    )
                )
            }
        }

        messageStatusPipeline.sink { status in
            guard status.type == .read, status.fromMe else {
                return
            }

            // Since this is only processing things on the SMS Read Buffer, we only want to continue
            // if we have a chat for this chatID on SMS
            guard IMChat.chat(withIdentifier: status.chatID, onService: .SMS) != nil else {
                return
            }

            self.pushToSMSReadBuffer(status.messageID)
        }
        .store(in: &bag)

        // Apparently in Ventura, macOS started ignoring certain chats to make the iMessage
        // service more lean, so we have to manually tell the system to listen to all of the
        // conversations that exist.
        // We're not 100% certain what will do this (listen to a conversation), so we're trying
        // all of these to see if any of them do the trick and will update later.
        if #available(macOS 13, *) {
            IMDMessageStore.sharedInstance().setSuppressDatabaseUpdates(false)

            for chat in IMChatRegistry.shared.allChats {
                chat.watchAllHandles()
            }
        }

        NotificationCenter.default.addObserver(forName: .IMAccountPrivacySettingsChanged, object: nil, queue: nil) {
            notification in
            guard let account = notification.object as? IMAccount else {
                return
            }

            guard let blockList = account.blockList as? [String] else {
                return log.debug("unexpected type for blockList: \(type(of: account.blockList))")
            }

            self.blocklistPipeline.send(blockList)
        }

        NotificationCenter.default.addObserver(forName: .IMChatJoinStateDidChange, object: nil, queue: nil) {
            notification in
            guard let chat = notification.object as? IMChat else {
                return
            }

            self.chatJoinStatePipeline.send((chat.chatIdentifier, chat.joinState))
        }
    }

    // MARK: - Chat events

    public override func groupPhotoUpdated(
        forChatIdentifier chatIdentifier: String!,
        style: IMChatStyle,
        account: String!,
        userInfo: [AnyHashable: Any]! = [:]
    ) {
        log.debug("chat:\(String(describing: chatIdentifier)) groupPhotoUpdated")
    }

    // Properties were changed
    public override func chat(_ persistentIdentifier: String, updated updateDictionary: [AnyHashable: Any]) {
        log.debug("chat:\(persistentIdentifier) updated:\(updateDictionary.singleLineDebugDescription)")
        apply(serializedChat: updateDictionary, emitIfNeeded: true)
    }

    // Group name changed
    public override func chat(_ persistentIdentifier: String!, displayNameUpdated displayName: String?) {
        log.debug("chat:\(String(describing: persistentIdentifier)) displayNameUpdated:\(displayName ?? "nil")")
        chatNamePipeline.send((persistentIdentifier.bl_mergedID, displayName))
    }

    public override func leftChat(_ persistentIdentifier: String!) {
        log.debug("leftChat:\(String(describing: persistentIdentifier))")
    }

    public override func loadedChats(_ chats: [[AnyHashable: Any]]!) {
        log.debug("loadedChats:\(chats.count)")
    }

    // A new chat has been created
    public override func chatLoaded(withChatIdentifier chatIdentifier: String!, chats chatDictionaries: [Any]!) {
        log.debug("chatLoaded:\(String(describing: chatIdentifier)), dicts:\(chatDictionaries.count)")
        for chat in chatDictionaries {
            guard let dict = chat as? [AnyHashable: Any] else {
                continue
            }

            apply(serializedChat: dict, emitIfNeeded: false)
        }
    }

    // MARK: - Message events

    // Invoked when we send a message, either here or elsewhere
    public override func account(
        _ accountUniqueID: String,
        chat chatIdentifier: String,
        style chatStyle: IMChatStyle,
        chatProperties properties: [AnyHashable: Any],
        groupID: String,
        chatPersonCentricID personCentricID: String!,
        messageSent msg: IMMessageItem
    ) {
        log.debug("messageSent: \(msg.singleLineDebugDescription)")
        chatIdentifierCache[msg.id] = chatIdentifier
        process(newMessage: msg, chatIdentifier: chatIdentifier)
    }

    // Invoked when we sent a message *locally*
    public override func account(
        _ accountUniqueID: String!,
        chat chatIdentifier: String!,
        style chatStyle: IMChatStyle,
        chatProperties properties: [AnyHashable: Any]!,
        notifySentMessage msg: IMMessageItem!,
        sendTime: NSNumber!
    ) {
        log.debug("notifySentMessage: \(msg.singleLineDebugDescription)")
        process(sentMessage: msg, sentTime: (msg.clientSendTime ?? msg.time ?? Date()).timeIntervalSince1970)
    }

    public override func account(
        _ accountUniqueID: String,
        chat chatIdentifier: String,
        style chatStyle: IMChatStyle,
        chatProperties properties: [AnyHashable: Any],
        groupID: String,
        chatPersonCentricID personCentricID: String,
        messageReceived msg: IMItem
    ) {
        log.debug("messageReceived: \(msg.singleLineDebugDescription)")

        process(newMessage: msg, chatIdentifier: chatIdentifier)
    }

    public override func account(
        _ accountUniqueID: String,
        chat chatIdentifier: String,
        style chatStyle: IMChatStyle,
        chatProperties properties: [AnyHashable: Any],
        groupID: String,
        chatPersonCentricID personCentricID: String,
        messagesReceived messages: [IMItem],
        messagesComingFromStorage fromStorage: Bool
    ) {
        log.debug("messagesReceived: \(messages.singleLineDebugDescription) comingFromStorage: \(fromStorage)")

        for message in messages {
            process(newMessage: message, chatIdentifier: chatIdentifier)
        }
    }

    public override func account(
        _ accountUniqueID: String!,
        chat chatIdentifier: String!,
        style chatStyle: IMChatStyle,
        chatProperties properties: [AnyHashable: Any]!,
        groupID: String!,
        chatPersonCentricID personCentricID: String!,
        messagesReceived messages: [IMItem]!
    ) {
        log.debug("messagesReceived: \(messages.singleLineDebugDescription)")

        for message in messages {
            process(newMessage: message, chatIdentifier: chatIdentifier)
        }
    }

    // Invoked for status updates (read/deliver/play/save/edit etc)
    public override func service(
        _ serviceID: String!,
        chat chatIdentifier: String!,
        style chatStyle: IMChatStyle,
        messagesUpdated messages: [[AnyHashable: Any]]!
    ) {
        log.debug("messagesUpdated[service]: \(messages.debugDescription.singleLineDebugDescription)")

        for message in CBCreateItemsFromSerializedArray(messages) {
            switch message {
            case let message as IMMessageItem:
                self.process(serviceMessage: message, chatIdentifier: chatIdentifier, chatStyle: chatStyle)
            default:
                return
            }
        }
    }

    public override func account(
        _ accountUniqueID: String!,
        chat chatIdentifier: String!,
        style chatStyle: IMChatStyle,
        chatProperties properties: [AnyHashable: Any]!,
        messageUpdated msg: IMItem!
    ) {
        account(
            accountUniqueID,
            chat: chatIdentifier,
            style: chatStyle,
            chatProperties: properties,
            messagesUpdated: [msg]
        )
    }

    public override func account(
        _ accountUniqueID: String!,
        chat chatIdentifier: String!,
        style chatStyle: IMChatStyle,
        chatProperties properties: [AnyHashable: Any]!,
        messagesUpdated messages: [NSObject]!
    ) {
        log.debug("messagesUpdated[account]: \(messages.debugDescription.singleLineDebugDescription)")

        for message in messages as? [IMItem] ?? CBCreateItemsFromSerializedArray(messages) {
            switch message {
            case let message as IMMessageItem:
                // This listener call is only for failed messages that are not otherwise caught.
                guard message.errorCode != .noError else {
                    log.debug(
                        "messagesUpdated[account]: ignoring message \(message.id) because it has no error. it will flow through another handler."
                    )
                    continue
                }
                guard
                    let chatIdentifier = chatIdentifier
                        ?? DBReader.shared.immediateChatIdentifier(forMessageGUID: message.id)
                else {
                    continue
                }
                self.process(newMessage: message, chatIdentifier: chatIdentifier)
            default:
                continue
            }
        }
    }

    public override func historicalMessageGUIDsDeleted(_ deletedGUIDs: [String], chatGUIDs: [String], queryID: String!)
    {
        if deletedGUIDs.count > 0 {
            messagesDeletedPipeline.send(deletedGUIDs)
        }

        if chatGUIDs.count > 0 {
            chatsDeletedPipeline.send(chatGUIDs)
        }
    }

    // MARK: - File Transfers

    public override func fileTransfer(_ guid: String!, createdWithProperties properties: [AnyHashable: Any]!) {
        log.debug(
            "CBDaemonListener.fileTransfer(_:createdWithProperties:) guid=\(String(describing: guid)) properties=\(String(describing: properties))"
        )
        Task {
            _ = await CBPurgedAttachmentController.shared.process(transferIDs: [guid])
        }
    }

    public override func fileTransfer(_ guid: String!, updatedWithProperties properties: [AnyHashable: Any]!) {
        log.debug(
            "CBDaemonListener.fileTransfer(_:updatedWithProperties:) guid=\(String(describing: guid)) properties=\(String(describing: properties))"
        )
        Task {
            _ = await CBPurgedAttachmentController.shared.process(transferIDs: [guid])
        }
    }

    public override func fileTransfers(_ guids: [Any]!, createdWithLocalPaths paths: [Any]!) {
        log.debug(
            "CBDaemonListener.fileTransfers(_:createdWithLocalPaths:) guids=\(String(describing: guids)) paths=\(String(describing: paths))"
        )
        super.fileTransfers(guids, createdWithLocalPaths: paths)
    }

    public override func standaloneFileTransferRegistered(_ guid: String!) {
        log.debug("CBDaemonListener.standaloneFileTransferRegistered(_:) guid=\(String(describing: guid))")
        super.standaloneFileTransferRegistered(guid)
    }

    public override func fileTransfer(
        _ guid: String!,
        updatedWithCurrentBytes currentBytes: UInt64,
        totalBytes: UInt64,
        averageTransferRate: UInt64
    ) {
        log.debug(
            "CBDaemonListener.fileTransfer(_:updatedWithCurrentBytes:totalBytes:averageTransferRate:) guid=\(String(describing: guid)) currentBytes=\(currentBytes) totalBytes=\(totalBytes) averageTransferRate=\(averageTransferRate)"
        )
        super
            .fileTransfer(
                guid,
                updatedWithCurrentBytes: currentBytes,
                totalBytes: totalBytes,
                averageTransferRate: averageTransferRate
            )
    }

    public override func fileTransferHighQualityDownloadFailed(_ guid: String!) {
        log.debug("CBDaemonListener.fileTransferHighQualityDownloadFailed(_:) guid=\(String(describing: guid))")
        super.fileTransferHighQualityDownloadFailed(guid)
    }

    public override func fileTransfer(_ guid: String!, highQualityDownloadSucceededWithPath path: String!) {
        log.debug(
            "CBDaemonListener.fileTransfer(_:highQualityDownloadSucceededWithPath:) guid=\(String(describing: guid)) path=\(String(describing: path))"
        )
    }
}

// MARK: - Chat Logic

extension CBDaemonListener {
    fileprivate func previousUnreadCount(forChatIdentifier chatIdentifier: String) -> Int {
        unreadCounts[chatIdentifier] ?? 0
    }

    fileprivate func extractParticipants(_ value: Any?) -> [String] {
        guard let array = value as? [NSDictionary] else {
            return []
        }

        return array.compactMap {
            $0["FZPersonID"] as? String
        }
    }

    fileprivate func apply(serializedChat dict: [AnyHashable: Any], emitIfNeeded: Bool = true) {
        guard let chatIdentifier = dict["chatIdentifier"] as? String else {
            log.debug("couldn't find chatIdentifier in serialized chat!")
            log.debug("\(dict.debugDescription)")
            return
        }

        if let unreadCount = (dict["unreadCount"] as? NSNumber)?.intValue {
            let previousUnreadCount = previousUnreadCount(forChatIdentifier: chatIdentifier)
            unreadCounts[chatIdentifier] = unreadCount

            if emitIfNeeded && previousUnreadCount != unreadCount {
                unreadCountPipeline.send((chatIdentifier, unreadCount))
            }
        }

        let displayName = dict["displayName"] as? String
        let previousDisplayName = displayNames[chatIdentifier]
        displayNames[chatIdentifier] = displayName

        if emitIfNeeded && previousDisplayName != displayName {
            chatNamePipeline.send((chatIdentifier, displayName))
        }
    }
}

// MARK: - Message Handling

extension CBDaemonListener {
    private func preflight(message: IMItem) -> Bool {
        lazy var messageItem: IMMessageItem? = message as? IMMessageItem
        lazy var sendProgress = messageItem?.sendProgress

        if nonces.contains(message.nonce) {
            // only let failed messages emit more than once, as failed messages may not first fail with their error code
            guard sendProgress == .failed else {
                log.debug("withholding message \(String(describing: message.guid)): dedupe")
                return false
            }
        }

        guard message.isFromMe, let message = messageItem else {
            // passthrough!
            nonces.insert(message.nonce)
            return true
        }

        if sendProgress == .failed, message.errorCode == .noError {
            log.debug(
                "withholding message \(String(describing: message.guid)): missing error code, message is either still in progress or the error code is coming soon"
            )
            return false
        }

        return true
    }

    fileprivate func process(sentMessage message: IMMessageItem, sentTime: Double) {
        guard
            let chatID = chatIdentifierCache[message.id]
                ?? DBReader.shared.immediateChatIdentifier(forMessageGUID: message.id)
        else {
            log.error("Failed to resolve chat identifier for sent message \(message.id)")
            return
        }

        guard let service = IMServiceStyle(rawValue: message.service) else {
            log.error("Cannot process sentMessage \(message): service is not a known value")
            return
        }

        messageStatusPipeline.send(
            CBMessageStatusChange(
                type: .sent,
                service: service,
                time: sentTime,
                sender: nil,
                fromMe: true,
                chatID: chatID,
                messageID: message.id,
                context: .init(message: message)
            )
        )
    }

    fileprivate func process(newMessage: IMItem, chatIdentifier: String) {
        if !preflight(message: newMessage) {
            log.warning("withholding message \(String(describing: newMessage.guid)): preflight failure")
            return
        }

        guard let serv = newMessage.service, let service = IMServiceStyle(rawValue: serv) else {
            log.warning(
                "Couldn't form relevant service from \(String(describing: newMessage.service)); ignoring message \(String(describing: newMessage.guid))"
            )
            return
        }

        var currentlyTyping: Bool {
            get { self.currentlyTyping.contains(chatIdentifier) }
            set {
                if newValue {
                    if self.currentlyTyping.insert(chatIdentifier).inserted {
                        typingPipeline.send((chatIdentifier, service, true))
                    }
                } else {
                    if self.currentlyTyping.remove(chatIdentifier) != nil {
                        typingPipeline.send((chatIdentifier, service, false))
                    }
                }
            }
        }

        switch newMessage {
        case let item as IMMessageItem:
            currentlyTyping = item.isIncomingTypingMessage() && !item.isCancelTypingMessage()

            // typing messages are not part of the timeline anymore
            if item.isTypingMessage {
                log.debug("ignoring message \(String(describing: item.guid)): typing doesnt flow through here")
                return
            }

            if item.isSpam {
                log.debug("ignoring message \(String(describing: item.guid)): flagged as spam")
                return
            }

            if item.errorCode == .remoteUserDoesNotExist {
                // Request Re-routing so that we can get more information on what this error means
                let guid = item.service + ";-;" + chatIdentifier
                IMDMessageServicesCenter.sharedInstance()
                    .requestRouting(forMessageGuid: item.guid, inChat: guid, error: nil) { response in
                        log.debug(
                            "Got response from requesting reroute for \(String(describing: item.guid)) in \(guid): \(response.singleLineDebugDescription)"
                        )
                    }
                return
            }

            log.debug(
                "sending message \(String(describing: item.guid)) \(String(describing: item.service)) \(chatIdentifier) down the pipeline"
            )
            messagePipeline.send(Message(messageItem: item, chatID: chatIdentifier, service: service))
        case let item:
            // wrap non-message items and send them as transcript actions
            switch transcriptRepresentation(item, chatID: chatIdentifier) {
            case let phantom as PhantomChatItem:
                phantomPipeline.send(phantom)
            case let representation:
                var additionalFileTransfers = [String]()

                switch representation {
                case let groupAction as GroupActionItem:
                    if groupAction.actionType.rawValue == 1,
                        let groupPhoto = IMChat.chat(withIdentifier: chatIdentifier, onService: service)?.groupPhotoID
                    {
                        additionalFileTransfers.append(groupPhoto)
                    }
                default:
                    break
                }

                messagePipeline.send(
                    Message(
                        item,
                        transcriptRepresentation: representation,
                        service: service,
                        additionalFileTransferGUIDs: additionalFileTransfers
                    )
                )
            }
        }
    }

    private func transcriptRepresentation(_ item: IMItem, chatID: String) -> ChatItem {
        switch item {
        case let item as IMParticipantChangeItem:
            return ParticipantChangeItem(item, chatID: chatID)
        case let item as IMGroupTitleChangeItem:
            return GroupTitleChangeItem(item, chatID: chatID)
        case let item as IMGroupActionItem:
            return GroupActionItem(item, chatID: chatID)
        default:
            return PhantomChatItem(item, chatID: chatID)
        }
    }
}

// MARK: - Service Messages

extension IMMessageItem {
    private var statusPayload: (type: CBMessageStatusType, time: Date)? {
        if errorCode.rawValue > 0 {
            return (.notDelivered, time)
        }

        if let timePlayed = timePlayed {
            return (.played, timePlayed)
        } else if let timeRead = timeRead {
            return (.read, timeRead)
        } else if let timeDelivered = timeDelivered {
            return (.delivered, timeDelivered)
        } else if wasDowngraded {
            return (.downgraded, time)
        } else {
            return nil
        }
    }

    fileprivate func statusChange(inChat chat: String, style: IMChatStyle) -> CBMessageStatusChange? {
        guard let payload = statusPayload, let service = IMServiceStyle(rawValue: service) else {
            return nil
        }

        var canBeFromOthers: Bool {
            style == .instantMessage
        }

        var fromMe: Bool {
            if style == .group {
                return payload.type != .played
            } else {
                switch payload.type {
                case .read:
                    if isFromMe() {
                        return false  // other user just read our message
                    } else {
                        return true  // we just read the chat
                    }
                case .delivered:
                    return false
                case .played:
                    return false
                case .downgraded:
                    return true
                case .notDelivered:
                    return true
                case .sent:
                    return true
                }
            }
        }

        /// Sender of the receipt, not sender of the message
        var sender: String? {
            if fromMe {
                return nil
            }

            if style == .group {
                return resolveSenderID(inService: serviceStyle)
            } else {
                return chat  // chat identifier for DM is just the recipient
            }
        }

        return CBMessageStatusChange(
            type: payload.type,
            service: service,
            time: payload.time.timeIntervalSince1970 * 1000,
            sender: sender,
            fromMe: fromMe,
            chatID: chat,
            messageID: id,
            context: CBMessageStatusChangeContext(message: self)
        )
    }
}

extension CBDaemonListener {
    fileprivate func process(serviceMessage message: IMMessageItem, chatIdentifier: String, chatStyle: IMChatStyle) {
        guard let messageStatus = message.statusChange(inChat: chatIdentifier, style: chatStyle) else {
            return
        }

        if message.isSpam {
            return
        }

        messageStatusPipeline.send(messageStatus)
    }
}

extension CBDaemonListener {
    func pushToSMSReadBuffer(_ guid: String) {
        guard !smsReadBuffer.contains(guid) else {
            return
        }
        log.debug("Adding \(guid) to sms read buffer", source: "ReadState")
        smsReadBuffer.append(guid)
        if smsReadBuffer.count > smsReadBufferCapacity {
            smsReadBuffer = smsReadBuffer.suffix(smsReadBufferCapacity)
        }
    }
}
