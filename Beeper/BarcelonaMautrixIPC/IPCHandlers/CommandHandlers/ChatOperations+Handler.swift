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
import Logging

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
    public func run(payload: IPCPayload, ipcChannel: MautrixIPCChannel) {
        if min_timestamp <= 0 {
            return payload.reply(withResponse: .chats_resolved(IMChatRegistry.shared.allChats.map(\.blChatGUID)), ipcChannel: ipcChannel)
        }

        Task {
            do {
                let timestamps = try await DBReader.shared.latestMessageTimestamps()

                let guids = timestamps.mapValues { timestamp, guid in
                    (IMDPersistenceTimestampToUnixSeconds(timestamp: timestamp), guid)
                }.filter { chatID, pair in
                    pair.0 > min_timestamp
                }.map(\.value.1)

                payload.reply(withResponse: .chats_resolved(guids.dedupeChatGUIDs()), ipcChannel: ipcChannel)
            } catch {
                payload.fail(strategy: .internal_error(error.localizedDescription), ipcChannel: ipcChannel)
            }
        }
    }
}

extension GetGroupChatInfoCommand: Runnable {
    var log: Logging.Logger {
        Logger(label: "TapbackCommand")
    }
    public func run(payload: IPCPayload, ipcChannel: MautrixIPCChannel) {
        log.info("Getting chat with id \(chat_guid)", source: "MautrixIPC")
        
        guard let chat = blChat else {
            return payload.fail(strategy: .chat_not_found, ipcChannel: ipcChannel)
        }
        
        payload.respond(.chat_resolved(chat), ipcChannel: ipcChannel)
    }
}

extension SendReadReceiptCommand: Runnable, AuthenticatedAsserting {
    var log: Logging.Logger {
        Logger(label: "TapbackCommand")
    }
    public func run(payload: IPCPayload, ipcChannel: MautrixIPCChannel) {
        log.info("Sending read receipt to \(String(describing: cbChat?.blChatGUID))", source: "MautrixIPC")

        guard let chat = cbChat else {
            return payload.fail(strategy: .chat_not_found, ipcChannel: ipcChannel)
        }

        chat.markMessageAsRead(withID: read_up_to)
    }
}

extension SendTypingCommand: Runnable, AuthenticatedAsserting {
    public func run(payload: IPCPayload, ipcChannel: MautrixIPCChannel) {
        guard let chat = cbChat else {
            return payload.fail(strategy: .chat_not_found, ipcChannel: ipcChannel)
        }
        
        chat.setTyping(typing)
    }
}

extension GetGroupChatAvatarCommand: Runnable {
    public func run(payload: IPCPayload, ipcChannel: MautrixIPCChannel) {
        guard let chat = chat, let groupPhotoID = chat.groupPhotoID else {
            return payload.respond(.chat_avatar(nil), ipcChannel: ipcChannel)
        }
        
        payload.respond(.chat_avatar(BLAttachment(guid: groupPhotoID)), ipcChannel: ipcChannel)
    }
}
