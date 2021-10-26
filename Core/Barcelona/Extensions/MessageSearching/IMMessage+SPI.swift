//
//  IMMessage+SPI.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 8/16/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import os.log

extension Array where Element == IMMessage {
    func bulkRepresentation(in chat: String) -> Promise<[Message]> {
        BLIngestObjects(self, inChat: chat).compactMap { $0 as? Message }
    }
}

private let message_log = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "IMMessage+SPI")

public extension IMMessage {
    /**
     Takes an IMMessageItem that has no context object and resolves it into a fully formed IMMessage
     */
    static func message(fromUnloadedItem item: IMMessageItem, withSubject subject: NSMutableAttributedString? = nil) -> IMMessage? {
        var rawSender: String? = item.sender()
        
        if item.sender() == nil, item.isFromMe(), let suitableHandle = Registry.sharedInstance.suitableHandle(for: item.service) {
            rawSender = suitableHandle.id
            item.accountID = suitableHandle.account.uniqueID
        }
        
        guard let senderID = rawSender, let account = item.imAccount, let sender = Registry.sharedInstance.imHandle(withID: senderID, onAccount: account) else {
            return nil
        }
        
        return IMMessage(fromIMMessageItem: item, sender: sender, subject: subject)!
    }
    
    static func message(withGUID guid: String, in chat: String? = nil) -> Promise<ChatItem?> {
        return messages(withGUIDs: [guid], in: chat).then(\.first)
    }
    
    static func messages(withGUIDs guids: [String], in chat: String? = nil) -> Promise<[ChatItem]> {
        if guids.count == 0 {
            return .success([])
        }
        
        if BLIsSimulation {
            return IMChatHistoryController.sharedInstance()!.loadMessages(withGUIDs: guids)
                    .compactMap(\._imMessageItem)
                    .then { items -> Promise<[ChatItem]> in
                        BLIngestObjects(items, inChat: chat)
                    }
        } else {
            return BLLoadChatItems(withGUIDs: guids, chatID: chat)
        }
    }
}
