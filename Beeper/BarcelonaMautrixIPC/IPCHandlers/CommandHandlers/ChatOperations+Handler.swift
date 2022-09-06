//
//  ChatOperations+Handler.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 8/23/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import Barcelona
import IMCore
import BarcelonaDB
import Swog

extension Array where Element == String {
    /// Given self is an array of chat GUIDs, masks the GUIDs to iMessage service and returns the deduplicated result
    func dedupeChatGUIDs() -> [String] {
        if MXFeatureFlags.shared.mergedChats {
            var guids: Set<String> = Set()
            for guid in self {
                if guid.hasPrefix("iMessage;") {
                    guids.insert(guid)
                } else if let firstSemi = guid.firstIndex(of: ";") {
                    guids.insert(String("iMessage" + guid[firstSemi...]))
                }
            }
            return Array(guids)
        } else {
            return Array(Set(self))
        }
    }
}

import BarcelonaMautrixIPCProtobuf

extension PBGetChatsRequest: Runnable {
    public func run(payload: IPCPayload) {
        if minTimestamp.timeIntervalSince1970 <= 0 {
            return payload.reply(withResponse: .chatList(.with {
                $0.chats = IMChatRegistry.shared.allChats.map(\.ipcGUID)
            }))
        }
        
        DBReader.shared.latestMessageTimestamps().values.filter {
            $0.message_date > minTimestamp.timeIntervalSince1970
        }.compactMap { marker in
            if marker.chat_identifier.isEmpty || marker.service_name.isEmpty {
                return nil
            }
            return PBGUID.with {
                $0.service = marker.service_name
                $0.isGroup = marker.style == 43
                $0.localID = marker.chat_identifier
            }
        }.then { chats in
            payload.reply(withResponse: .chatList(.with {
                $0.chats = chats
            }))
        }
    }
}

extension PBGUID {
    var imService: IMService? {
        switch service {
        case "iMessage": return .iMessage()
        case "SMS": return .sms()
        default: return nil
        }
    }
    
    var exactIMAccount: IMAccount? {
        imService.flatMap {
            IMAccountController.shared.bestAccount(forService: $0)
        }
    }
    
    var imAccount: IMAccount? {
        exactIMAccount ?? IMAccountController.shared.activeAccounts.first
    }
    
    var imHandle: IMHandle? {
        guard !isGroup else {
            return nil
        }
        return imAccount.flatMap {
            $0.imHandle(withID: localID)
        }
    }
    
    var imChat: IMChat? {
        if localID.isEmpty {
            return nil
        }
        if isGroup {
            return IMChatRegistry.shared.existingChat(withChatIdentifier: localID)
        } else if let imHandle = imHandle {
            return IMChatRegistry.shared.chat(for: imHandle)
        } else {
            return IMChatRegistry.shared.existingChat(withGUID: rawValue)
        }
    }
    
    var chat: Chat? {
        imChat.map(Chat.init(_:))
    }
    
    var cbChat: CBChat? {
        CBChatRegistry.shared.chats[.chatIdentifier(localID)] ?? imChat.flatMap(CBChatRegistry.shared.chat(for:)).map(\.0)
    }
}

extension IMHandle {
    var ipcGUID: PBGUID {
        .with {
            $0.service = service.name
            $0.isGroup = false
            $0.localID = idWithoutResource
        }
    }
}

extension CBChat {
    func searchLeaves<T>(_ callback: (CBChatLeaf) throws -> T?) rethrows -> T? {
        for leaf in leaves.values {
            if let value = try callback(leaf) {
                return value
            }
        }
        return nil
    }

    var displayName: String? {
        guard style == .group else {
            return nil
        }
        return searchLeaves(\.IMChat?.displayName)
    }

    var mostRecentChat: IMChat? {
        leaves.values.sorted(usingKey: \.lastSentMesageDate, by: >).lazy.first?.IMChat
    }

    var pb: PBChatInfo? {
        guard let mostRecentChat = mostRecentChat else {
            return nil
        }
        return PBChatInfo.with {
            $0.guid = mostRecentChat.ipcGUID
            mostRecentChat.displayName.oassign(to: &$0.displayName)
            (mostRecentChat.participants?.compactMap(\.idWithoutResource)).oassign(to: &$0.members)
            mostRecentChat.correlationIdentifier.oassign(to: &$0.correlationID)
        }
    }
}

extension PBGetChatRequest: Runnable {
    public func run(payload: IPCPayload) {
        CLInfo("MautrixIPC", "Getting chat with id %@", chatGuid.rawValue)
        
        guard let pb = chatGuid.cbChat?.pb else {
            return payload.fail(strategy: .chat_not_found)
        }
        
        payload.respond(.chat(pb))
    }
}

extension PBSendReadReceiptRequest: Runnable, AuthenticatedAsserting {
    public func run(payload: IPCPayload) {
        guard let chat = chatGuid.chat else {
            return payload.fail(strategy: .chat_not_found)
        }
        
        chat.markMessageAsRead(withID: readUpTo)
    }
}

extension PBSetTypingRequest: Runnable, AuthenticatedAsserting {
    public func run(payload: IPCPayload) {
        guard let chat = chatGuid.chat else {
            return payload.fail(strategy: .chat_not_found)
        }
        
        chat.setTyping(typing)
    }
}

extension PBGetChatAvatarRequest: Runnable {
    public func run(payload: IPCPayload) {
        guard let chat = chatGuid.chat, let groupPhotoID = chat.groupPhotoID, let attachment = PBAttachment(guid: groupPhotoID) else {
            return payload.respond(.null(true))
        }
        payload.respond(.attachment(attachment))
    }
}
