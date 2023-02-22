//
//  CBChatRegistry.swift
//  Barcelona
//
//  Created by Eric Rabil on 8/8/22.
//

import BarcelonaDB
import Combine
import Foundation
import IMCore
import IMDPersistence
import IMFoundation
import IMSharedUtilities
import Logging

private let IMCopyThreadNameForChat: (@convention(c) (String, String, IMChatStyle) -> Unmanaged<NSString>)? =
    CBWeakLink(against: .privateFramework(name: "IMFoundation"), .symbol("IMCopyThreadNameForChat"))

public class CBChatRegistry: NSObject, IMDaemonListenerProtocol {
    public var chats: [CBChatIdentifier: CBChat] = [:]
    public var allChats: [ObjectIdentifier: CBChat] = [:]

    var messageIDReverseLookup: [String: CBChatIdentifier] = [:]
    private var subscribers: Set<AnyCancellable> = Set()

    private let log = Logger(label: "CBChatRegistry")

    override init() {
        super.init()
        IMDaemonController.shared().listener.addHandler(self)
    }

    public func setupComplete(_ success: Bool, info: [AnyHashable: Any]!) {
        if let chats = info["personMergedChats"] as? [[AnyHashable: Any]] {
            for chat in chats {
                _ = handle(chat: chat)
            }
        } else {
            log.warning("Did not receive personMergedChats in setup info")
        }
    }

    public func chat(_ persistentIdentifier: String!, updated updateDictionary: [AnyHashable: Any]!) {
        trace(
            nil,
            nil,
            "persistentIdentifier \(persistentIdentifier!) updated \(updateDictionary.singleLineDebugDescription)"
        )
        _ = handle(chat: updateDictionary)
    }

    public func chat(_ persistentIdentifier: String!, propertiesUpdated properties: [AnyHashable: Any]!) {
        trace(
            nil,
            nil,
            "persistentIdentifier \(persistentIdentifier!) properties \(properties.singleLineDebugDescription)"
        )
        _ = handle(chat: [
            "guid": persistentIdentifier as Any,
            "properties": properties as Any,
        ])
    }

    public func chat(_ persistentIdentifier: String!, engramIDUpdated engramID: String!) {
        trace(nil, nil, "persistentIdentifier \(persistentIdentifier!) engram \(engramID ?? "nil")")
    }

    public func chat(_ guid: String!, lastAddressedHandleUpdated lastAddressedHandle: String!) {

    }

    var loadedChatsByChatIdentifierCallback: [String: [([IMChat]) -> Void]] = [:]

    public func chatLoaded(withChatIdentifier chatIdentifier: String!, chats chatDictionaries: [Any]!) {
        trace(chatIdentifier, nil, "chats loaded: \((chatDictionaries as NSArray))")
        guard let callbacks = loadedChatsByChatIdentifierCallback.removeValue(forKey: chatIdentifier) else {
            return
        }
        let parsed = internalize(chats: chatDictionaries.compactMap { $0 as? [AnyHashable: Any] })
        for callback in callbacks {
            callback(parsed)
        }
    }

    public func lastMessage(forAllChats chatIDToLastMessageDictionary: [AnyHashable: Any]!) {
        trace(nil, nil, "loaded last message for all chats \((chatIDToLastMessageDictionary as NSDictionary))")
    }

    public func service(
        _ serviceID: String!,
        chat chatIdentifier: String!,
        style chatStyle: IMChatStyle,
        messagesUpdated messages: [[AnyHashable: Any]]!
    ) {
        trace(chatIdentifier, nil, "messages updated \(messages.singleLineDebugDescription)")
        messages.forEach {
            handle(chat: .chatIdentifier(chatIdentifier), item: $0)
        }
    }

    public func account(
        _ accountUniqueID: String!,
        chat chatIdentifier: String!,
        style chatStyle: IMChatStyle,
        chatProperties properties: [AnyHashable: Any]!,
        error: Error!
    ) {
        trace(chatIdentifier, nil, "error \((error as NSError).debugDescription)")
    }

    public func account(
        _ accountUniqueID: String!,
        chat chatIdentifier: String!,
        style chatStyle: IMChatStyle,
        chatProperties properties: [AnyHashable: Any]!,
        notifySentMessage msg: IMMessageItem!,
        sendTime: NSNumber!
    ) {
        trace(chatIdentifier, nil, "sent message \(msg.guid ?? "nil") \(msg.singleLineDebugDescription)")
        handle(chatIdentifier: chatIdentifier, properties: properties, groupID: nil, item: msg)
    }

    private func trace(
        _ chatIdentifier: String!,
        _ personCentricID: String!,
        _ message: String,
        _ function: StaticString = #function
    ) {
        log.debug(
            "chat \(chatIdentifier ?? "nil") pcID \(personCentricID ?? "nil") \(message): \(function.description)"
        )
    }

    public func account(
        _ accountUniqueID: String!,
        chat chatIdentifier: String!,
        style chatStyle: IMChatStyle,
        chatProperties properties: [AnyHashable: Any]!,
        groupID: String!,
        chatPersonCentricID personCentricID: String!,
        messagesReceived messages: [IMItem]!,
        messagesComingFromStorage fromStorage: Bool
    ) {
        trace(chatIdentifier, personCentricID, "received \(messages!) from storage \(fromStorage)")
        messages.forEach {
            handle(chatIdentifier: chatIdentifier, properties: properties, groupID: groupID, item: $0)
        }
    }

    public func account(
        _ accountUniqueID: String!,
        chat chatIdentifier: String!,
        style chatStyle: IMChatStyle,
        chatProperties properties: [AnyHashable: Any]!,
        groupID: String!,
        chatPersonCentricID personCentricID: String!,
        statusChanged status: FZChatStatus,
        handleInfo: [Any]!
    ) {

    }

    public func account(
        _ accountUniqueID: String!,
        chat chatIdentifier: String!,
        style chatStyle: IMChatStyle,
        chatProperties properties: [AnyHashable: Any]!,
        groupID: String!,
        chatPersonCentricID personCentricID: String!,
        messagesReceived messages: [IMItem]!
    ) {
        trace(chatIdentifier, personCentricID, "received \(messages!)")
        messages.forEach {
            handle(chatIdentifier: chatIdentifier, properties: properties, groupID: groupID, item: $0)
        }
    }

    public func account(
        _ accountUniqueID: String!,
        chat chatIdentifier: String!,
        style chatStyle: IMChatStyle,
        chatProperties properties: [AnyHashable: Any]!,
        groupID: String!,
        chatPersonCentricID personCentricID: String!,
        messageReceived msg: IMItem!
    ) {
        trace(chatIdentifier, personCentricID, "received message \(msg.singleLineDebugDescription)")
        handle(chatIdentifier: chatIdentifier, properties: properties, groupID: groupID, item: msg)
    }

    private func handle(chatIdentifier: String?, properties: [AnyHashable: Any]?, groupID: String?, item: NSObject) {
        lazy var guid: String? = {
            switch item {
            case let item as IMItem:
                return item.guid
            case let item as NSDictionary:
                return item["guid"] as? String
            default:
                return nil
            }
        }()
        lazy var messageID: Int64? = {
            switch item {
            case let item as IMItem:
                return item.messageID
            case let item as NSDictionary:
                return item["messageID"] as? Int64
            default:
                return nil
            }
        }()
        var reverseChatIdentifier: CBChatIdentifier? {
            guid.flatMap { messageIDReverseLookup[$0] }
        }
        var chatID: CBChatIdentifier? {
            if let properties = properties, let id = handle(chat: properties).1 {
                return id
            } else if let reverseChatIdentifier = reverseChatIdentifier {
                return reverseChatIdentifier
            } else if let groupID = groupID {
                return .groupID(groupID)
            } else if let chatIdentifier = chatIdentifier {
                return .chatIdentifier(chatIdentifier)
            } else if let messageID = messageID {
                func withPersistenceAccess<P>(_ callback: () throws -> P) rethrows -> P {
                    if !IMDIsRunningInDatabaseServerProcess() {
                        IMDSetIsRunningInDatabaseServerProcess(1)
                        defer {
                            IMDSetIsRunningInDatabaseServerProcess(0)
                        }
                        return try callback()
                    } else {
                        return try callback()
                    }
                }
                return withPersistenceAccess {
                    if let chat = IMDChatRecordCopyChatForMessageID(messageID),
                        let chatGUID = IMDChatRecordCopyGUID(kCFAllocatorDefault, chat)
                    {
                        return .guid(chatGUID as String)
                    }
                    return nil
                }
            }
            return nil
        }
        guard let chatID = chatID else {
            trace(chatIdentifier, nil, "dropping message \(guid ?? "nil") because i cant find the chat its for?!")
            return
        }
        handle(chat: chatID, item: item)
    }

    public func account(
        _ accountUniqueID: String!,
        chat chatIdentifier: String!,
        style chatStyle: IMChatStyle,
        chatProperties properties: [AnyHashable: Any]!,
        groupID: String!,
        chatPersonCentricID personCentricID: String!,
        messageSent msg: IMMessageItem!
    ) {
        trace(chatIdentifier, personCentricID, "sent message \(msg)")
        handle(chatIdentifier: chatIdentifier, properties: properties, groupID: groupID, item: msg)
    }

    public func account(
        _ accountUniqueID: String!,
        chat chatIdentifier: String!,
        style chatStyle: IMChatStyle,
        chatProperties properties: [AnyHashable: Any]!,
        updateProperties update: [AnyHashable: Any]!
    ) {
        trace(
            chatIdentifier,
            nil,
            "properties \(((properties ?? [:]) as NSDictionary)) updated to \(((update ?? [:]) as NSDictionary).singleLineDebugDescription)"
        )
    }

    public func account(
        _ accountUniqueID: String!,
        chat chatIdentifier: String!,
        style chatStyle: IMChatStyle,
        chatProperties properties: [AnyHashable: Any]!,
        messageUpdated msg: IMItem!
    ) {
        trace(chatIdentifier, nil, "message updated \(msg)")
        handle(chatIdentifier: chatIdentifier, properties: properties, groupID: nil, item: msg)
    }

    public func account(
        _ accountUniqueID: String!,
        chat chatIdentifier: String!,
        style chatStyle: IMChatStyle,
        chatProperties properties: [AnyHashable: Any]!,
        messagesUpdated messages: [NSObject]!
    ) {
        trace(chatIdentifier, nil, "messages updated \((messages! as NSArray).singleLineDebugDescription)")
        messages.forEach {
            handle(chatIdentifier: chatIdentifier, properties: properties, groupID: nil, item: $0)
        }
    }

    var queryCallbacks: [String: [() -> Void]] = [:]

    private func internalize(chats: [[AnyHashable: Any]]) -> [IMChat] {
        func getMutableDictionary(_ key: String) -> NSMutableDictionary {
            if let dict = IMChatRegistry.shared.value(forKey: key) as? NSMutableDictionary {
                return dict
            }
            let dict = NSMutableDictionary()
            IMChatRegistry.shared.setValue(dict, forKey: key)
            return dict
        }
        func getMutableArray(_ key: String) -> NSMutableArray {
            if let array = IMChatRegistry.shared.value(forKey: key) as? NSMutableArray {
                return array
            }
            let array = NSMutableArray()
            IMChatRegistry.shared.setValue(array, forKey: key)
            return array
        }
        // 0x20 <= Big Sur, 0x78 Monterey
        lazy var chatGUIDToChatMap: NSMutableDictionary = getMutableDictionary("_chatGUIDToChatMap")
        // 0xb0 <= Big Sur, 0xb8 Monterey
        lazy var groupIDToChatMap: NSMutableDictionary = getMutableDictionary("_groupIDToChatMap")
        // 0x10 <= Big Sur, 0x80 Monterey
        lazy var chatGUIDToCurrentThreadMap: NSMutableDictionary = getMutableDictionary("_chatGUIDToCurrentThreadMap")
        // 0x30 <= Big Sur, 0x90 Monterey
        lazy var threadNameToChatMap: NSMutableDictionary = getMutableDictionary("_threadNameToChatMap")
        lazy var allChatsInThreadNameMap: NSMutableArray = {
            if #available(macOS 12, *) {
                // 0xa8
                return getMutableArray("_cachedChatsInThreadNameMap")
            } else {
                // 0x40
                return getMutableArray("_allChatsInThreadNameMap")
            }
        }()
        return chats.compactMap { chat in
            let guid = chat["guid"] as? String
            _ = handle(chat: chat)
            if let guid = guid, let existingChat = chatGUIDToChatMap[guid] as? IMChat, existingChat.guid == guid {
                return existingChat
            }
            guard
                let imChat = IMChat()
                    ._init(withDictionaryRepresentation: chat, items: nil, participantsHint: nil, accountHint: nil)
            else {
                return nil
            }
            if let groupID = chat["groupID"] as? String {
                groupIDToChatMap[groupID] = imChat
            }
            if let guid = guid {
                chatGUIDToChatMap[guid] = imChat
                if let IMCopyThreadNameForChat = IMCopyThreadNameForChat,
                    let chatIdentifier = chat["chatIdentifier"] as? String,
                    let accountID = imChat.account.uniqueID
                {
                    let threadName = IMCopyThreadNameForChat(chatIdentifier, accountID, imChat.chatStyle)
                    if chatGUIDToCurrentThreadMap[guid] == nil {
                        chatGUIDToCurrentThreadMap[guid] = threadName
                    }
                    if threadNameToChatMap[threadName] == nil {
                        threadNameToChatMap[threadName] = imChat
                    }
                }
            }
            if !allChatsInThreadNameMap.containsObjectIdentical(to: imChat) {
                allChatsInThreadNameMap.add(imChat)
            }
            return imChat
        }
    }

    public func loadedChats(_ chats: [[AnyHashable: Any]]!, queryID: String!) {
        guard queryCallbacks.keys.contains(queryID) else {
            return
        }
        _ = internalize(chats: chats)
        for callback in queryCallbacks.removeValue(forKey: queryID) ?? [] {
            callback()
        }
    }

    var hasLoadedChats = false
    var loadedChatsCallbacks: [() -> Void] = []
    private let loadedChatsCallbacksLock = NSRecursiveLock()

    public func loadedChats(_ chats: [[AnyHashable: Any]]!) {
        _ = internalize(chats: chats)
        loadedChatsCallbacksLock.withLock {
            let loadedChatsCallbacks = loadedChatsCallbacks
            self.loadedChatsCallbacks = []
            for callback in loadedChatsCallbacks {
                callback()
            }
        }
    }

    public func onLoadedChats(_ callback: @escaping () -> Void) {
        if hasLoadedChats {
            callback()
        } else {
            loadedChatsCallbacksLock.withLock {
                loadedChatsCallbacks.append(callback)
            }
        }
    }
}

extension CBChatRegistry {
    public static let shared = CBChatRegistry()

    public func handle(chat: [AnyHashable: Any]) -> (CBChat?, CBChatIdentifier?) {
        var leaf = CBChatLeaf()
        leaf.handle(identifiable: chat)

        enum FoundError: Error { case found(CBChat) }
        do {
            try leaf.forEachIdentifier { identifier in
                if let cbChat = self.chats[identifier] {
                    cbChat.handle(dictionary: chat)
                    //                    log.debug("Notifying CBChat of updated chat \(String(describing: identifier))")
                    throw FoundError.found(cbChat)
                }
            }
        } catch {
            guard case .found(let chat) = error as? FoundError else {
                preconditionFailure()
            }
            return (chat, leaf.mostUniqueIdentifier)
        }

        guard let style = (chat["style"] as? CBChatStyle.RawValue).flatMap(CBChatStyle.init(rawValue:)) else {
            return (nil, leaf.mostUniqueIdentifier)
        }
        let cbChat = CBChat(style: style)
        cbChat.handle(dictionary: chat)
        store(chat: cbChat)
        return (cbChat, leaf.mostUniqueIdentifier)
    }

    public func handle(chat: CBChatIdentifier, item: [AnyHashable: Any]) {
        if let guid = item["guid"] as? String, !messageIDReverseLookup.keys.contains(guid) {
            messageIDReverseLookup[guid] = chat
        }
        if let cbChat = chats[chat] {
            cbChat.handle(leaf: chat, item: item)
        } else {
            log.info("where is chat?!")
        }
    }

    @_disfavoredOverload
    public func handle(chat: CBChatIdentifier, item: NSObject) {
        switch item {
        #if canImport(IMSharedUtilities)
        case let item as IMItem:
            handle(chat: chat, item: item)
        #endif
        case let item as [AnyHashable: Any]:
            handle(chat: chat, item: item)
        case let item:
            preconditionFailure(
                "This method only accepts IMItem subclasses or dictionaries, but you gave me \(String(describing: type(of: item)))"
            )
        }
    }

    private func store(chat: CBChat) {
        allChats[ObjectIdentifier(chat)] = chat
        chat.$identifiers.removeDuplicates()
            .scan((Set<CBChatIdentifier>(), Set<CBChatIdentifier>())) {
                ($0.1, $1)
            }
            .sink { oldIdentifiers, newIdentifiers in
                var newIdentifiers = newIdentifiers
                for identifier in oldIdentifiers {
                    let existed = newIdentifiers.remove(identifier) != nil
                    if existed {
                        continue
                    }
                    if self.chats[identifier] === chat {
                        self.log.warning("Forgetting \(String(describing: identifier))")
                        self.chats[identifier] = nil
                    }
                }
                for identifier in newIdentifiers {
                    if let chat = self.chats[identifier] {
                        if chat !== chat {
                            self.log.warning(
                                "Encountered two different CBChats with the same identifier \(String(describing: identifier))"
                            )
                        }
                        continue
                    }
                    //                self.log.info("Storing \(String(describing: identifier))")
                    self.chats[identifier] = chat
                }
            }
            .store(in: &subscribers)
    }
}

#if canImport(IMSharedUtilities)
extension CBChatRegistry {
    public func handle(chat: [AnyHashable: Any], item: IMItem) -> Bool {
        guard let identifier = handle(chat: chat).1 else {
            log.warning("cant handle message \(item) via chat dictionary: couldnt find a chat for it")
            return false
        }
        handle(chat: identifier, item: item)
        return true
    }

    public func handle(chat: CBChatIdentifier, item: IMItem) {
        if let guid = item.guid, !messageIDReverseLookup.keys.contains(guid) {
            messageIDReverseLookup[guid] = chat
        }
        if let cbChat = chats[chat] {
            cbChat.handle(leaf: chat, item: item)
        } else {
            log.info("where is chat?!")
        }
    }
}
#endif
