//
//  GetMessagesAfter+Handler.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 8/23/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import Barcelona
import BarcelonaMautrixIPCProtobuf

extension PBGetMessagesAfterRequest: Runnable, AuthenticatedAsserting {
    public func run(payload: IPCPayload) {
        #if DEBUG
        IPCLog("Getting messages for chat guid %@ after time %f", chatGuid.rawValue, timestamp.timeIntervalSince1970)
        #endif
        
        guard let chat = chatGuid.imChat else {
            #if DEBUG
            IPCLog.debug("Unknown chat with guid %@", chatGuid.rawValue)
            #endif
            return payload.fail(strategy: .chat_not_found)
        }
        
        let siblings = chat.siblings
        
        if let lastMessageTime = siblings.compactMap(\.lastMessage?.time?.timeIntervalSince1970).max(),
           lastMessageTime < timestamp.timeIntervalSince1970 {
            #if DEBUG
            IPCLog.debug("Not processing get_messages_after because chats last message timestamp %f is before req.timestamp %f", lastMessageTime, timestamp.timeIntervalSince1970)
            #endif
            return payload.respond(.messages(.init()))
        }
        
        BLLoadChatItems(withChatIdentifiers: siblings.compactMap(\.chatIdentifier), onServices: .CBMessageServices, afterDate: timestamp.date, limit: Int(limit)).then(\.blMessages).then { messages in
            payload.respond(.messages(.with {
                $0.messages = messages
            }))
        }
    }
}

extension PBGetRecentMessagesRequest: Runnable, AuthenticatedAsserting {
    public func run(payload: IPCPayload) {
        guard let chat = chatGuid.imChat else {
            return payload.fail(strategy: .chat_not_found)
        }
        
        let siblings = chat.siblings
        
        BLLoadChatItems(withChatIdentifiers: siblings.compactMap(\.chatIdentifier), onServices: .CBMessageServices, limit: Int(limit)).then(\.blMessages).then { messages in
            payload.respond(.messages(.with {
                $0.messages = messages
            }))
        }
    }
}

extension PBHistoryQuery: Runnable {
    public func run(payload: IPCPayload) {
        guard let chat = chatGuid.imChat else {
            return payload.fail(strategy: .chat_not_found)
        }

        let siblings = chat.siblings

        BLLoadChatItems(
            withChatIdentifiers: siblings.compactMap(\.chatIdentifier),
            onServices: .CBMessageServices,
            afterDate: (hasAfterDate ? afterDate : nil)?.date,
            beforeDate: (hasBeforeDate ? beforeDate : nil)?.date,
            afterGUID: (hasAfterGuid ? afterGuid : nil),
            beforeGUID: (hasBeforeGuid ? beforeGuid : nil),
            limit: (hasLimit ? limit : nil).flatMap(Int.init(_:))
        ).then(\.blMessages)
         .then { messages in
             payload.respond(.messages(.with {
                 $0.messages = messages
             }))
         }
    }
}