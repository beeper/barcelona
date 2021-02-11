//
//  Tapbacks.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/7/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import NIO

extension DBReader {
    /// Loads messages associated with the given GUIDs
    /// - Parameters:
    ///   - guids: GUIDs of messages to resolve associations
    ///   - chat: ID of the chat the messages reside in. if omitted, they will be resolved at ingestion
    /// - Returns: Dictionary of GUIDs from the guids parameter to an array of associated messages
    func associatedMessages(with guids: [String], in chat: String? = nil) -> EventLoopFuture<[String: [Message]]> {
        if guids.count == 0 { return eventLoop.makeSucceededFuture([:]) }
        let promise = eventLoop.makePromise(of: [String: [Message]].self)
        
        if ERBarcelonaManager.isSimulation {
            EventLoopFuture<[String: [Message]]>.whenAllSucceed(guids.map { guid -> EventLoopFuture<[String: [Message]]> in
                guard let chat = IMChatRegistry.shared._chats(withMessageGUID: guid).first else {
                    return eventLoop.makeSucceededFuture([guid: []])
                }

                let associatedGUIDs = chat.chatItems.compactMap {
                    $0 as? IMAssociatedMessageChatItem
                }.filter {
                    $0.associatedMessageGUID == guid
                }.compactMap {
                    $0.associatedMessageGUID
                }

                return Message.lazyResolve(withIdentifiers: associatedGUIDs, inChat: chat.id, on: eventLoop).map {
                    [guid: $0]
                }
            }, on: eventLoop).map {
                $0.reduce(into: [String: [Message]]()) { ledger, subLedger in
                    ledger.merge(subLedger) { m1, m2 in
                        []
                    }
                }
            }.cascade(to: promise)

            return promise.futureResult
        }
        
        pool.asyncRead { result in
            switch result {
            case .failure(let error):
                promise.fail(error)
            case .success(let db):
                do {
                    let messages = try RawMessage
                        .select(RawMessage.Columns.guid, as: String.self)
                        .filter(guids.contains(RawMessage.Columns.associated_message_guid))
                        .fetchAll(db)
                    
                    Message.dirtyMessages(withGUIDs: messages, in: chat, on: self.eventLoop).map {
                        $0.reduce(into: [String: [Message]]()) { ledger, message in
                            guard let associatedMessageGUID = message.associatedMessageID else { return }
                            if ledger[associatedMessageGUID] == nil { ledger[associatedMessageGUID] = [] }
                            ledger[associatedMessageGUID]!.append(message)
                        }
                    }.cascade(to: promise)
                } catch {
                    promise.fail(error)
                }
            }
        }
        
        return promise.futureResult
    }
    
    /// Resolves associated messages with the given GUID
    /// - Parameter guid: GUID of the message to load associations
    /// - Returns: array of Messages
    func associatedMessages(with guid: String) -> EventLoopFuture<[Message]> {
        let promise = eventLoop.makePromise(of: [Message].self)

        pool.asyncRead { result in
            switch result {
            case .failure(let error):
                promise.fail(error)
                return
            case .success(let db):
                do {
                    let messages = try RawMessage
                        .select(RawMessage.Columns.guid, RawMessage.Columns.ROWID)
                        .filter(sql: "associated_message_guid = ?", arguments: [guid])
                        .fetchAll(db)
                    
                    Message.messages(withGUIDs: messages.map { $0.guid! }, on: self.eventLoop).cascade(to: promise)
                } catch {
                    print("Failed to resolve chat group IDs for messages with error \(error)")
                    promise.succeed([])
                    return
                }
            }
            
        }
        
        return promise.futureResult
    }
}
