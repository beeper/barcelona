//
//  IMMessage+SPI.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 8/16/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import IMSharedUtilities
import os.log

private let message_log = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "IMMessage+SPI")

extension IMMessage {
    /**
     Takes an IMMessageItem that has no context object and resolves it into a fully formed IMMessage
     */
    public static func message(
        fromUnloadedItem item: IMMessageItem,
        withSubject subject: NSMutableAttributedString?
    ) -> IMMessage? {
        var rawSender: String? = item.resolveSenderID(inService: item.serviceStyle)

        if item.sender() == nil, item.isFromMe(),
            let suitableHandle = Registry.sharedInstance.suitableHandle(for: item.service)
        {
            rawSender = suitableHandle.id
            item.accountID = suitableHandle.account.uniqueID
        }

        guard let senderID = rawSender, let account = item.imAccount,
            let sender = Registry.sharedInstance.imHandle(withID: senderID, onAccount: account)
        else {
            return nil
        }

        return IMMessage(fromIMMessageItem: item, sender: sender, subject: subject)!
    }

    public static func message(fromUnloadedItem item: IMMessageItem) -> IMMessage? {
        message(fromUnloadedItem: item, withSubject: nil)
    }

    public static func message(
        withGUID guid: String,
        in chat: String? = nil,
        service: IMServiceStyle
    ) async throws -> ChatItem? {
        try await messages(withGUIDs: [guid], in: chat, service: service).first
    }

    public static func messages(
        withGUIDs guids: [String],
        in chat: String? = nil,
        service: IMServiceStyle
    ) async throws -> [ChatItem] {
        if guids.count == 0 {
            return []
        }

        if BLIsSimulation {
            let items = await IMChatHistoryController.sharedInstance()!.loadMessages(withGUIDs: guids)
                .compactMap(\._imMessageItem)
            return try await BLIngestObjects(items, inChat: chat, service: service)
        } else {
            return try await BLLoadChatItems(withGUIDs: guids, chatID: chat, service: service)
        }
    }
}
