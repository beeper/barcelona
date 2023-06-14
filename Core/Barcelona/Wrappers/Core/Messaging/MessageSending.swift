//
//  MessageSending.swift
//  Barcelona
//
//  Created by Eric Rabil on 11/2/21.
//

import BarcelonaDB
import Combine
import Foundation
import IMCore
import IMDPersistence
import Logging

extension Chat {
    private func markAsRead() {
        if ProcessInfo.processInfo.environment.keys.contains("BARCELONA_GHOST_REPLIES") {
            return
        }
        imChat.markAllMessagesAsRead()
    }

    public func sendReturningRaw(message createMessage: CreateMessage) async -> IMMessage {
        return await imChat.send(message: createMessage)
    }

    public func send(message createMessage: CreateMessage) async throws -> Message {
        guard let service else {
            throw BarcelonaError(code: 500, message: "No service for \(id)")
        }

        return Message(
            messageItem: await sendReturningRaw(message: createMessage)._imMessageItem,
            chatID: imChat.chatIdentifier,
            service: service
        )
    }

    public func tapback(_ creation: TapbackCreation) async throws -> Message {
        markAsRead()
        guard let service else {
            throw BarcelonaError(code: 500, message: "No service for \(id)")
        }

        let message = try await imChat.tapback(
            guid: creation.message,
            itemGUID: creation.item,
            type: creation.type,
            overridingItemType: nil
        )

        return Message(messageItem: message._imMessageItem, chatID: imChat.chatIdentifier, service: service)
    }
}
