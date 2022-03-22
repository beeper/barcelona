//
//  GetMessagesAfter+Handler.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 8/23/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import Barcelona

extension GetMessagesAfterCommand: Runnable, AuthenticatedAsserting {
    public func run(payload: IPCPayload) {
        #if DEBUG
        IPCLog("Getting messages for chat guid %@ after time %f", chat_guid, timestamp)
        #endif
        
        guard let chat = chat else {
            #if DEBUG
            IPCLog.debug("Unknown chat with guid %@", chat_guid)
            #endif
            return payload.fail(strategy: .chat_not_found)
        }
        
        if let lastMessage = chat.lastMessage, lastMessage.time!.timeIntervalSince1970 < timestamp {
            #if DEBUG
            IPCLog.debug("Not processing get_messages_after because chats last message timestamp %f is before req.timestamp %f", lastMessage.time!.timeIntervalSince1970, timestamp)
            #endif
            return payload.respond(.messages([]))
        }
        
        BLLoadChatItems(withChatIdentifier: chat.id, onServices: .CBMessageServices, afterDate: date, limit: limit).then {
            $0.blMessages
        }.then {
            payload.respond(.messages($0))
        }
    }
}

extension GetRecentMessagesCommand: Runnable, AuthenticatedAsserting {
    public func run(payload: IPCPayload) {
        guard let chat = chat else {
            return payload.fail(strategy: .chat_not_found)
        }
        
        BLLoadChatItems(withChatIdentifier: chat.id, onServices: .CBMessageServices, limit: limit).then {
            $0.blMessages
        }.then {
            payload.respond(.messages($0))
        }
    }
}
