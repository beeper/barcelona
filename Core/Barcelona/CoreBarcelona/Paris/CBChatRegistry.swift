//
//  CBChatRegistry.swift
//  Barcelona
//
//  Created by Eric Rabil on 8/8/22.
//

import Foundation
import IMCore
import Swog
import Combine
import BarcelonaDB
import IMDPersistence

public class CBChatRegistry: NSObject, IMDaemonListenerProtocol {
    public var chats: [CBChatIdentifier: CBChat] = [:]
    public var allChats: [ObjectIdentifier: CBChat] = [:]
    
    var messageIDReverseLookup: [String: CBChatIdentifier] = [:]
    private var subscribers: Set<AnyCancellable> = Set()
    
    private let log = Logger(category: "CBChatRegistry", subsystem: "com.ericrabil.barcelona.CBChatRegistry")
    
    override init() {
        super.init()
        IMDaemonController.shared().listener.addHandler(self)
    }
    
    public func setupComplete(_ success: Bool, info: [AnyHashable : Any]!) {
        if let chats = info["personMergedChats"] as? [[AnyHashable: Any]] {
            for chat in chats {
                _ = handle(chat: chat)
            }
        } else {
            log.warn("Did not receive personMergedChats in setup info")
        }
    }
    
    public func chat(_ persistentIdentifier: String!, updated updateDictionary: [AnyHashable : Any]!) {
        trace(nil, nil, "persistentIdentifier \(persistentIdentifier!) updated \(((updateDictionary ?? [:]) as NSDictionary).prettyJSON)")
        _ = handle(chat: updateDictionary)
    }
    
    public func chat(_ persistentIdentifier: String!, propertiesUpdated properties: [AnyHashable : Any]!) {
        trace(nil, nil, "persistentIdentifier \(persistentIdentifier!) properties \(((properties ?? [:]) as NSDictionary).prettyJSON)")
        _ = handle(chat: [
            "guid": persistentIdentifier,
            "properties": properties
        ])
    }
    
    public func chat(_ persistentIdentifier: String!, engramIDUpdated engramID: String!) {
        trace(nil, nil, "persistentIdentifier \(persistentIdentifier!) engram \(engramID ?? "nil")")
    }
    
    public func chat(_ guid: String!, lastAddressedHandleUpdated lastAddressedHandle: String!) {
        
    }
    
    public func chatLoaded(withChatIdentifier chatIdentifier: String!, chats chatDictionaries: [Any]!) {
        trace(chatIdentifier, nil, "chats loaded: \((chatDictionaries as NSArray).prettyJSON)")
    }
    
    public func loadedChats(_ chats: [[AnyHashable : Any]]!) {
        trace(nil, nil, "loaded chats \((chats as NSArray).prettyJSON)")
    }
    
    public func lastMessage(forAllChats chatIDToLastMessageDictionary: [AnyHashable : Any]!) {
        trace(nil, nil, "loaded last message for all chats \((chatIDToLastMessageDictionary as NSDictionary).prettyJSON)")
    }
    
    public func service(_ serviceID: String!, chat chatIdentifier: String!, style chatStyle: IMChatStyle, messagesUpdated messages: [[AnyHashable: Any]]!) {
        trace(chatIdentifier, nil, "messages updated \((messages as! NSArray).prettyJSON)")
        messages.forEach {
            handle(chat: .chatIdentifier(chatIdentifier), item: $0)
        }
    }
    
    public func account(_ accountUniqueID: String!, chat chatIdentifier: String!, style chatStyle: IMChatStyle, chatProperties properties: [AnyHashable : Any]!, error: Error!) {
        trace(chatIdentifier, nil, "error \((error as NSError).debugDescription)")
    }
    
    public func account(_ accountUniqueID: String!, chat chatIdentifier: String!, style chatStyle: IMChatStyle, chatProperties properties: [AnyHashable : Any]!, notifySentMessage msg: IMMessageItem!, sendTime: NSNumber!) {
        trace(chatIdentifier, nil, "sent message \(msg.guid ?? "nil") \(msg.prettyJSON)")
        handle(chatIdentifier: chatIdentifier, properties: properties, groupID: nil, item: msg)
    }
    
    private func trace(_ chatIdentifier: String!, _ personCentricID: String!, _ message: String, _ function: StaticString = #function) {
        defer { visited = Set() }
        log.debug("chat \(chatIdentifier ?? "nil", privacy: .public) pcID \(personCentricID ?? "nil", privacy: .public) \(message, privacy: .public): \(function.description, privacy: .public)")
    }
    
    public func account(_ accountUniqueID: String!, chat chatIdentifier: String!, style chatStyle: IMChatStyle, chatProperties properties: [AnyHashable : Any]!, groupID: String!, chatPersonCentricID personCentricID: String!, messagesReceived messages: [IMItem]!, messagesComingFromStorage fromStorage: Bool) {
        trace(chatIdentifier, personCentricID, "received \(messages!.prettyJSON) from storage \(fromStorage)")
        messages.forEach {
            handle(chatIdentifier: chatIdentifier, properties: properties, groupID: groupID, item: $0)
        }
    }
    
    public func account(_ accountUniqueID: String!, chat chatIdentifier: String!, style chatStyle: IMChatStyle, chatProperties properties: [AnyHashable : Any]!, groupID: String!, chatPersonCentricID personCentricID: String!, statusChanged status: FZChatStatus, handleInfo: [Any]!) {
        
    }
    
    public func account(_ accountUniqueID: String!, chat chatIdentifier: String!, style chatStyle: IMChatStyle, chatProperties properties: [AnyHashable : Any]!, groupID: String!, chatPersonCentricID personCentricID: String!, messagesReceived messages: [IMItem]!) {
        trace(chatIdentifier, personCentricID, "received \(messages!.prettyJSON)")
        messages.forEach {
            handle(chatIdentifier: chatIdentifier, properties: properties, groupID: groupID, item: $0)
        }
    }
    
    public func account(_ accountUniqueID: String!, chat chatIdentifier: String!, style chatStyle: IMChatStyle, chatProperties properties: [AnyHashable : Any]!, groupID: String!, chatPersonCentricID personCentricID: String!, messageReceived msg: IMItem!) {
        trace(chatIdentifier, personCentricID, "received message \(msg.prettyJSON)")
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
                       let chatGUID = IMDChatRecordCopyGUID(kCFAllocatorDefault, chat) {
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
    
    public func account(_ accountUniqueID: String!, chat chatIdentifier: String!, style chatStyle: IMChatStyle, chatProperties properties: [AnyHashable : Any]!, groupID: String!, chatPersonCentricID personCentricID: String!, messageSent msg: IMMessageItem!) {
        trace(chatIdentifier, personCentricID, "sent message \(msg.prettyJSON)")
        handle(chatIdentifier: chatIdentifier, properties: properties, groupID: groupID, item: msg)
    }
    
    public func account(_ accountUniqueID: String!, chat chatIdentifier: String!, style chatStyle: IMChatStyle, chatProperties properties: [AnyHashable : Any]!, updateProperties update: [AnyHashable : Any]!) {
        trace(chatIdentifier, nil, "properties \(((properties ?? [:]) as NSDictionary).prettyJSON) updated to \(((update ?? [:]) as NSDictionary).prettyJSON)")
    }
    
    public func account(_ accountUniqueID: String!, chat chatIdentifier: String!, style chatStyle: IMChatStyle, chatProperties properties: [AnyHashable : Any]!, messageUpdated msg: IMItem!) {
        trace(chatIdentifier, nil, "message updated \(msg.prettyJSON)")
        handle(chatIdentifier: chatIdentifier, properties: properties, groupID: nil, item: msg)
    }
    
    public func account(_ accountUniqueID: String!, chat chatIdentifier: String!, style chatStyle: IMChatStyle, chatProperties properties: [AnyHashable : Any]!, messagesUpdated messages: [NSObject]!) {
        trace(chatIdentifier, nil, "messages updated \((messages! as NSArray).prettyJSON)")
        messages.forEach {
            handle(chatIdentifier: chatIdentifier, properties: properties, groupID: nil, item: $0)
        }
    }
    
    var queryCallbacks: [String: [() -> ()]] = [:]
    
    public func loadedChats(_ chats: [[AnyHashable : Any]]!, queryID: String!) {
        guard queryCallbacks.keys.contains(queryID) else {
            return
        }
        for chat in chats {
            let guid = chat["guid"] as? String
            if let existingChat = IMChatRegistry.shared.allChats.first(where: { $0.guid == guid }) {
                continue
            }
            guard let imChat = IMChat()._init(withDictionaryRepresentation: chat, items: nil, participantsHint: nil, accountHint: nil) else {
                continue
            }
            let hash = IMChatRegistry.shared._sortedParticipantIDHash(forParticipants: imChat.participants)
            IMChatRegistry.shared._addChat(imChat, participantSet: hash)
            (IMChatRegistry.shared.value(forKey: "_chatGUIDToChatMap") as! NSMutableDictionary)[guid] = imChat
            print(imChat)
        }
        for callback in queryCallbacks.removeValue(forKey: queryID) ?? [] {
            callback()
        }
    }
}

public extension CBChatRegistry {
    static let shared = CBChatRegistry()
    
    func handle(chat: [AnyHashable: Any]) -> (CBChat?, CBChatIdentifier?) {
        var leaf = CBChatLeaf()
        leaf.handle(identifiable: chat)
        
        enum FoundError: Error { case found(CBChat) }
        do {
            try leaf.forEachIdentifier { identifier in
                if let cbChat = self.chats[identifier] {
                    cbChat.handle(dictionary: chat)
//                    log.debug("Notifying CBChat of updated chat \(String(describing: identifier), privacy: .public)")
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
    
    func handle(chat: CBChatIdentifier, item: [AnyHashable: Any]) {
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
    func handle(chat: CBChatIdentifier, item: NSObject) {
        switch item {
            #if canImport(IMSharedUtilities)
        case let item as IMItem:
            handle(chat: chat, item: item)
            #endif
        case let item as [AnyHashable: Any]:
            handle(chat: chat, item: item)
        case let item:
            preconditionFailure("This method only accepts IMItem subclasses or dictionaries, but you gave me \(String(describing: type(of: item)))")
        }
    }
    
    private func store(chat: CBChat) {
        allChats[ObjectIdentifier(chat)] = chat
        chat.$identifiers.removeDuplicates().scan((Set<CBChatIdentifier>(), Set<CBChatIdentifier>())) {
            ($0.1, $1)
        }.sink { oldIdentifiers, newIdentifiers in
            var newIdentifiers = newIdentifiers
            for identifier in oldIdentifiers {
                let existed = newIdentifiers.remove(identifier) != nil
                if existed {
                    continue
                }
                if self.chats[identifier] === chat {
                    self.log.warn("Forgetting \(String(describing: identifier), privacy: .public)")
                    self.chats[identifier] = nil
                }
            }
            for identifier in newIdentifiers {
                if let chat = self.chats[identifier] {
                    if chat !== chat {
                        self.log.warn("Encountered two different CBChats with the same identifier \(String(describing: identifier), privacy: .public)")
                    }
                    continue
                }
//                self.log.info("Storing \(String(describing: identifier), privacy: .public)")
                self.chats[identifier] = chat
            }
        }.store(in: &subscribers)
    }
}

#if canImport(IMSharedUtilities)
public extension CBChatRegistry {
    func handle(chat: [AnyHashable: Any], item: IMItem) -> Bool {
        guard let identifier = handle(chat: chat).1 else {
            log.warn("cant handle message \(item, privacy: .auto) via chat dictionary: couldnt find a chat for it")
            return false
        }
        handle(chat: identifier, item: item)
        return true
    }
    
    func handle(chat: CBChatIdentifier, item: IMItem) {
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
