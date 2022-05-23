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

extension GetChatsCommand: Runnable {
    public func run(payload: IPCPayload) {
        if min_timestamp <= 0 {
            return payload.reply(withResponse: .chats_resolved(IMChatRegistry.shared.allChats.map(\.blChatGUID)))
        }
        
        DBReader.shared.latestMessageTimestamps().then { timestamps in
            timestamps.mapValues { timestamp, guid in
                (IMDPersistenceTimestampToUnixSeconds(timestamp: timestamp), guid)
            }
        }.filter { chatID, pair in
            pair.0 > min_timestamp
        }.map(\.value.1).then { guids in
            payload.reply(withResponse: .chats_resolved(guids.dedupeChatGUIDs()))
        }
    }
}

extension GetGroupChatInfoCommand: Runnable {
    public func run(payload: IPCPayload) {
        CLInfo("MautrixIPC", "Getting chat with id %@", chat_guid)
        
        guard let chat = blChat else {
            return payload.fail(strategy: .chat_not_found)
        }
        
        payload.respond(.chat_resolved(chat))
    }
}

extension SendReadReceiptCommand: Runnable, AuthenticatedAsserting {
    public func run(payload: IPCPayload) {
        guard let chat = cbChat else {
            return payload.fail(strategy: .chat_not_found)
        }
        
        chat.markMessageAsRead(withID: read_up_to)
    }
}

extension SendTypingCommand: Runnable, AuthenticatedAsserting {
    public func run(payload: IPCPayload) {
        guard let chat = cbChat else {
            return payload.fail(strategy: .chat_not_found)
        }
        
        chat.setTyping(typing)
    }
}

extension GetGroupChatAvatarCommand: Runnable {
    public func run(payload: IPCPayload) {
        guard let chat = chat, let groupPhotoID = chat.groupPhotoID else {
            return payload.respond(.chat_avatar(nil))
        }
        
        payload.respond(.chat_avatar(BLAttachment(guid: groupPhotoID)))
    }
}
