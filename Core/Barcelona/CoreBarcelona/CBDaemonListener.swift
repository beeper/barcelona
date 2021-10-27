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

import Foundation
import IMCore
import Swexy
import Swog
import BarcelonaDB

private let log = Logger(category: "ERDaemonListener")

// set to false and the logging conditions (probably) wont even compile, but they will be disabled
private let loggingEnabled = false

prefix operator *

@_transparent
prefix func *(_ expression: @autoclosure () -> ()) {
    // TODO: replace with compilation condition to have this compile to nothing
    if _slowPath(loggingEnabled) {
        expression()
    }
}

private extension String {
    var bl_mergedID: String {
        if let lastIndex = lastIndex(of: ";") {
            return String(self[index(after: lastIndex)...])
        }
        
        return self
    }
}

private extension IMItem {
    var nonce: Int {
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
}

private struct CBMessageStatusChangeContext {
    var message: IMMessageItem?
}

// Represents the different updates that are made to a message
public struct CBMessageStatusChange: Codable, Hashable {
    public static func == (lhs: CBMessageStatusChange, rhs: CBMessageStatusChange) -> Bool {
        false
    }
    
    fileprivate init(type: CBMessageStatusType, time: Double, sender: String? = nil, fromMe: Bool, chatID: String, messageID: String, context: CBMessageStatusChangeContext = .init()) {
        self.type = type
        self.time = time
        self.sender = sender
        self.fromMe = fromMe
        self.chatID = chatID
        self.messageID = messageID
        self.context = context
    }
    
    public var type: CBMessageStatusType
    public var time: Double
    public var sender: String?
    public var fromMe: Bool
    public var chatID: String
    public var messageID: String
    
    // backing storage for the message object used to create this
    private var context: CBMessageStatusChangeContext = .init()
    
    public var chat: IMChat {
        IMChat.resolve(withIdentifier: chatID) ?? IMChat()
    }
    
    public var message: IMMessageItem {
        context.message ?? IMMessageItem()
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(time)
        hasher.combine(sender)
        hasher.combine(fromMe)
        hasher.combine(chatID)
        hasher.combine(messageID)
    }
    
    private enum CodingKeys : String, CodingKey {
        case type, time, sender, fromMe, chatID, messageID
    }
}

public class CBDaemonListener: ERBaseDaemonListener {
    public static let shared = CBDaemonListener()
    
    public let unreadCountPipeline = CBPipeline<(chat: String, count: Int)>()
    public let typingPipeline = CBPipeline<(chat: String, typing: Bool)>()
    public let chatNamePipeline = CBPipeline<(chat: String, name: String?)>()
    public let chatParticipantsPipeline = CBPipeline<(chat: String, participants: [String])>()
    
    public let messagePipeline = CBPipeline<Message>()
    public let phantomPipeline = CBPipeline<PhantomChatItem>()
    public let messageStatusPipeline = CBPipeline<CBMessageStatusChange>()
    
    public let messagesDeletedPipeline = CBPipeline<[String]>()
    public let chatsDeletedPipeline = CBPipeline<[String]>()
    
    // Caches for determining whether an update notification is needed
    private var unreadCounts: [String: Int] = [:]
    private var displayNames: [String: String] = [:]
    private var participants: [String: [String]] = [:]
    
    private var currentlyTyping = Set<String>()
    
    // Dedupes messages sent from self - we should have a cleanup routine for this
    private var nonces = Set<Int>()
    
    public override func setupComplete(_ success: Bool, info: [AnyHashable : Any]!) {
        log.debug("setup: \(success)")
        
        if let info = info, let dicts = (info["personMergedChats"] ?? info["chats"]) as? [[AnyHashable: Any]] {
            for dict in dicts {
                apply(serializedChat: dict, emitIfNeeded: false)
            }
        }
        
        guard ProcessInfo.processInfo.environment["BLNoBlocklist"] == nil else {
            return
        }
        
        ERSharedBlockList()._connect()
    }
    
    // MARK: - Chat events
    
    public override func groupPhotoUpdated(forChatIdentifier chatIdentifier: String!, style: IMChatStyle, account: String!, userInfo: [AnyHashable : Any]! = [:]) {
        *log.debug("chat:\(chatIdentifier) groupPhotoUpdated")
    }
    
    // Properties were changed
    public override func chat(_ persistentIdentifier: String, updated updateDictionary: [AnyHashable : Any]) {
        *log.debug("chat:\(persistentIdentifier, privacy: .public) updated:\(updateDictionary.debugDescription, privacy: .public)")
        apply(serializedChat: updateDictionary, emitIfNeeded: true)
    }
    
    // Group name changed
    public override func chat(_ persistentIdentifier: String!, displayNameUpdated displayName: String?) {
        *log.debug("chat:\(persistentIdentifier, privacy: .public) displayNameUpdated:\(displayName ?? "nil", privacy: .public)")
        chatNamePipeline.send((persistentIdentifier.bl_mergedID, displayName))
    }
    
    public override func leftChat(_ persistentIdentifier: String!) {
        *log.debug("leftChat:\(persistentIdentifier, privacy: .public)")
    }
    
    public override func loadedChats(_ chats: [[AnyHashable : Any]]!) {
        *log.debug("loadedChats:\(chats.count, privacy: .public)")
    }
    
    // A new chat has been created
    public override func chatLoaded(withChatIdentifier chatIdentifier: String!, chats chatDictionaries: [Any]!) {
        *log.debug("chatLoaded:\(chatIdentifier, privacy: .public), dicts:\(chatDictionaries.count, privacy: .public)")
        for chat in chatDictionaries {
            guard let dict = chat as? [AnyHashable: Any] else {
                continue
            }
            
            apply(serializedChat: dict, emitIfNeeded: false)
        }
    }
    
    // MARK: - Message events
    
    // Invoked when we send a message, either here or elsewhere
    public override func account(_ accountUniqueID: String, chat chatIdentifier: String, style chatStyle: IMChatStyle, chatProperties properties: [AnyHashable : Any], groupID: String, chatPersonCentricID personCentricID: String!, messageSent msg: IMMessageItem) {
        *log.debug("messageSent: \(msg.debugDescription, privacy: .public)")
        
        process(newMessage: msg, chatIdentifier: chatIdentifier)
        nonces.insert(msg.nonce)
    }
    
    public override func account(_ accountUniqueID: String, chat chatIdentifier: String, style chatStyle: IMChatStyle, chatProperties properties: [AnyHashable : Any], groupID: String, chatPersonCentricID personCentricID: String, messageReceived msg: IMItem) {
        *log.debug("messageReceived: \(msg.debugDescription, privacy: .public)")
        
        process(newMessage: msg, chatIdentifier: chatIdentifier)
        nonces.insert(msg.nonce)
    }
    
    public override func account(_ accountUniqueID: String, chat chatIdentifier: String, style chatStyle: IMChatStyle, chatProperties properties: [AnyHashable : Any], groupID: String, chatPersonCentricID personCentricID: String, messagesReceived messages: [IMItem], messagesComingFromStorage fromStorage: Bool) {
        *log.debug("messagesReceived: \(messages.debugDescription, privacy: .public)")
        
        for message in messages {
            process(newMessage: message, chatIdentifier: chatIdentifier)
            nonces.insert(message.nonce)
        }
    }
    
    // Invoked for status updates (read/deliver/play/save etc)
    public override func service(_ serviceID: String!, chat chatIdentifier: String!, style chatStyle: IMChatStyle, messagesUpdated messages: [Any]!) {
        *log.debug("messagesUpdated[service]: \(messages.debugDescription, privacy: .public)")
        
        for message in FZCreateIMMessageItemsFromSerializedArray(messages) {
            switch message {
            case let message as IMMessageItem:
                self.process(serviceMessage: message, chatIdentifier: chatIdentifier, chatStyle: chatStyle)
            default:
                return
            }
        }
    }
    
    public override func historicalMessageGUIDsDeleted(_ deletedGUIDs: [String], chatGUIDs: [String], queryID: String!) {
        if deletedGUIDs.count > 0 {
            messagesDeletedPipeline.send(deletedGUIDs)
        }
        
        if chatGUIDs.count > 0 {
            chatsDeletedPipeline.send(chatGUIDs)
        }
    }
    
    // MARK: - File Transfers
    
    public override func fileTransfer(_ guid: String!, createdWithProperties properties: [AnyHashable : Any]!) {
        _ = CBPurgedAttachmentController.shared.process(transferIDs: [guid])
    }
    
    public override func fileTransfer(_ guid: String!, updatedWithProperties properties: [AnyHashable : Any]!) {
        _ = CBPurgedAttachmentController.shared.process(transferIDs: [guid])
    }
}

// MARK: - Chat Logic

private extension CBDaemonListener {
    func previousUnreadCount(forChatIdentifier chatIdentifier: String) -> Int {
        unreadCounts[chatIdentifier] ?? 0
    }
    
    func extractParticipants(_ value: Any?) -> [String] {
        guard let array = value as? [NSDictionary] else {
            return []
        }
        
        return array.compactMap {
            $0["FZPersonID"] as? String
        }
    }
    
    func apply(serializedChat dict: [AnyHashable: Any], emitIfNeeded: Bool = true) {
        guard let chatIdentifier = dict["chatIdentifier"] as? String else {
            log.debug("couldn't find chatIdentifier in serialized chat!")
            *log.debug("\(dict.debugDescription, privacy: .public)")
            return
        }
        
        let unreadCount = (dict["unreadCount"] as? NSNumber)?.intValue ?? 0
        let previousUnreadCount = previousUnreadCount(forChatIdentifier: chatIdentifier)
        unreadCounts[chatIdentifier] = unreadCount
        
        if emitIfNeeded && previousUnreadCount != unreadCount {
            unreadCountPipeline.send((chatIdentifier, unreadCount))
        }
        
        let displayName = dict["displayName"] as? String
        let previousDisplayName = displayNames[chatIdentifier]
        displayNames[chatIdentifier] = displayName
        
        if emitIfNeeded && previousDisplayName != displayName {
            chatNamePipeline.send((chatIdentifier, displayName))
        }
        
        apply(chatIdentifier: chatIdentifier, participants: extractParticipants(dict["participants"]), emitIfNeeded: emitIfNeeded)
    }
    
    func apply(chatIdentifier: String, participants chatParticipants: [String], emitIfNeeded: Bool = true) {
        let previousParticipants = participants[chatIdentifier] ?? []
        participants[chatIdentifier] = chatParticipants
        
        if emitIfNeeded && previousParticipants != chatParticipants {
            chatParticipantsPipeline.send((chatIdentifier, chatParticipants))
        }
    }
}

// MARK: - Message Handling

private extension CBDaemonListener {
    func process(newMessage: IMItem, chatIdentifier: String) {
        var currentlyTyping: Bool {
            get { self.currentlyTyping.contains(chatIdentifier) }
            set {
                if newValue {
                    if self.currentlyTyping.insert(chatIdentifier).inserted {
                        typingPipeline.send((chatIdentifier, true))
                    }
                } else {
                    if self.currentlyTyping.remove(chatIdentifier) != nil {
                        typingPipeline.send((chatIdentifier, false))
                    }
                }
            }
        }
        
        if nonces.contains(newMessage.nonce) {
            nonces.remove(newMessage.nonce)
            return
        }
        
        switch newMessage {
        case let item as IMMessageItem:
            currentlyTyping = item.isIncomingTypingMessage() && !item.isCancelTypingMessage()
            
            // typing messages are not part of the timeline anymore
            if item.isTypingMessage {
                return
            }
            
            messagePipeline.send(Message(messageItem: item, chatID: chatIdentifier))
        case let item:
            // wrap non-message items and send them as transcript actions
            switch transcriptRepresentation(item, chatID: chatIdentifier) {
            case let phantom as PhantomChatItem:
                phantomPipeline.send(phantom)
            case let representation:
                var additionalFileTransfers = [String]()
                
                switch representation {
                case let participantChange as ParticipantChangeItem:
                    guard let targetID = participantChange.targetID, var chatParticipants = participants[chatIdentifier] else {
                        break
                    }
                    
                    // Apply participant change to the cached participants and emit if needed
                    if participantChange.changeType == 0 && !chatParticipants.contains(targetID) {
                        chatParticipants.append(targetID)
                        apply(chatIdentifier: chatIdentifier, participants: chatParticipants, emitIfNeeded: true)
                    } else if participantChange.changeType == 1 && chatParticipants.contains(targetID) {
                        chatParticipants.removeAll(where: { $0 == targetID })
                        apply(chatIdentifier: chatIdentifier, participants: chatParticipants, emitIfNeeded: true)
                    }
                case let groupAction as GroupActionItem:
                    if groupAction.actionType.rawValue == 1, let groupPhoto = IMChat.resolve(withIdentifier: chatIdentifier)?.groupPhotoID {
                        additionalFileTransfers.append(groupPhoto)
                    }
                default:
                    break
                }
                
                messagePipeline.send(Message(item, transcriptRepresentation: representation, additionalFileTransferGUIDs: additionalFileTransfers))
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

private extension IMMessageItem {
    private var statusPayload: (type: CBMessageStatusType, time: Date)? {
        if let timePlayed = timePlayed {
            return (.played, timePlayed)
        } else if let timeRead = timeRead {
            return (.read, timeRead)
        } else if let timeDelivered = timeDelivered {
            return (.delivered, timeDelivered)
        } else if wasDowngraded {
            return (.downgraded, time)
        } else if errorCode > 0 {
            return (.notDelivered, time)
        } else {
            return nil
        }
    }
    
    func statusChange(inChat chat: String, style: IMChatStyle) -> CBMessageStatusChange? {
        guard let payload = statusPayload else {
            return nil
        }
        
        var canBeFromOthers: Bool {
            switch style {
            case .groupChatStyle:
                return false
            default:
                return true
            }
        }
        
        var fromMe: Bool {
            if canBeFromOthers {
                return isFromMe()
            } else {
                return true
            }
        }
        
        var sender: String? {
            if canBeFromOthers {
                return resolveSenderID(inService: serviceStyle)
            } else {
                return nil
            }
        }
        
        return CBMessageStatusChange(type: payload.type, time: payload.time.timeIntervalSince1970 * 1000, sender: sender, fromMe: fromMe, chatID: chat, messageID: id, context: CBMessageStatusChangeContext(message: self))
    }
}

private extension CBDaemonListener {
    func process(serviceMessage message: IMMessageItem, chatIdentifier: String, chatStyle: IMChatStyle) {
        guard let messageStatus = message.statusChange(inChat: chatIdentifier, style: chatStyle) else {
            return
        }
        
        messageStatusPipeline.send(messageStatus)
    }
}
