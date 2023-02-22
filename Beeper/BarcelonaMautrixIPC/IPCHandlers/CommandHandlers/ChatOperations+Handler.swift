//
//  ChatOperations+Handler.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 8/23/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Barcelona
import BarcelonaDB
import Foundation
import IMCore
import Logging
import Sentry

extension Array where Element == String {
    /// Given self is an array of chat GUIDs, masks the GUIDs to iMessage service and returns the deduplicated result
    func dedupeChatGUIDs() -> [String] {
        Array(Set(self))
    }
}

extension GetChatsCommand: Runnable {
    public func run(payload: IPCPayload, ipcChannel: MautrixIPCChannel) async {
        let span = SentrySDK.startTransaction(name: "GetChatsCommand", operation: "run", bindToScope: true)
        if min_timestamp <= 0 {
            payload.reply(
                withResponse: .chats_resolved(IMChatRegistry.shared.allChats.map(\.blChatGUID)),
                ipcChannel: ipcChannel
            )
            span.finish()
            return
        }

        do {
            let timestamps = try await DBReader.shared.latestMessageTimestamps()

            let guids =
                timestamps.mapValues { timestamp, guid in
                    (IMDPersistenceTimestampToUnixSeconds(timestamp: timestamp), guid)
                }
                .filter { chatID, pair in
                    pair.0 > min_timestamp
                }
                .map(\.value.1)

            payload.reply(withResponse: .chats_resolved(guids.dedupeChatGUIDs()), ipcChannel: ipcChannel)
            span.finish()
        } catch {
            payload.fail(strategy: .internal_error(error.localizedDescription), ipcChannel: ipcChannel)
            SentrySDK.capture(error: error)
            span.finish(status: .internalError)
        }
    }
}

extension GetGroupChatInfoCommand: Runnable {
    var log: Logging.Logger {
        Logger(label: "TapbackCommand")
    }
    public func run(payload: IPCPayload, ipcChannel: MautrixIPCChannel) async {
        log.info("Getting chat with id \(chat_guid)", source: "MautrixIPC")

        guard let chat = await blChat else {
            return payload.fail(strategy: .chat_not_found, ipcChannel: ipcChannel)
        }

        payload.respond(.chat_resolved(chat), ipcChannel: ipcChannel)
    }
}

extension SendReadReceiptCommand: Runnable, AuthenticatedAsserting {
    var log: Logging.Logger {
        Logger(label: "TapbackCommand")
    }
    public func run(payload: IPCPayload, ipcChannel: MautrixIPCChannel) async {
        let chatGUID = await cbChat?.blChatGUID
        log.info("Sending read receipt to \(String(describing: chatGUID))", source: "MautrixIPC")

        guard let chat = await cbChat else {
            return payload.fail(strategy: .chat_not_found, ipcChannel: ipcChannel)
        }

        chat.markMessageAsRead(withID: read_up_to)
    }
}

extension SendTypingCommand: Runnable, AuthenticatedAsserting {
    public func run(payload: IPCPayload, ipcChannel: MautrixIPCChannel) async {
        guard let chat = await cbChat else {
            return payload.fail(strategy: .chat_not_found, ipcChannel: ipcChannel)
        }

        chat.setTyping(typing)
    }
}

extension GetGroupChatAvatarCommand: Runnable {
    public func run(payload: IPCPayload, ipcChannel: MautrixIPCChannel) async {
        guard let chat = await chat, let groupPhotoID = chat.groupPhotoID else {
            return payload.respond(.chat_avatar(nil), ipcChannel: ipcChannel)
        }

        payload.respond(.chat_avatar(BLAttachment(guid: groupPhotoID)), ipcChannel: ipcChannel)
    }
}
