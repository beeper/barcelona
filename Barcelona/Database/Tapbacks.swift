//
//  Tapbacks.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/7/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

extension DBReader {
    /// Loads messages associated with the given GUIDs
    /// - Parameters:
    ///   - guids: GUIDs of messages to resolve associations
    ///   - chat: ID of the chat the messages reside in. if omitted, they will be resolved at ingestion
    /// - Returns: Dictionary of GUIDs from the guids parameter to an array of associated messages
    func associatedMessages(with guids: [String], in chat: String? = nil) -> Promise<[String: [Message]], Error> {
        if guids.count == 0 { return .success([:]) }
        
        if BLIsSimulation {
            return Promise.whenAllSucceed(guids.map { guid -> Promise<[String: [Message]], Error> in
                guard let chat = IMChatRegistry.shared._chats(withMessageGUID: guid).first else {
                    return .success([guid: []])
                }

                let associatedGUIDs = chat.chatItems.compactMap {
                    $0 as? IMAssociatedMessageChatItem
                }.filter {
                    $0.associatedMessageGUID == guid
                }.compactMap {
                    $0.associatedMessageGUID
                }

                return Message.lazyResolve(withIdentifiers: associatedGUIDs, inChat: chat.id).map {
                    [guid: $0]
                }
            }).map {
                $0.reduce(into: [String: [Message]]()) { ledger, subLedger in
                    ledger.merge(subLedger) { m1, m2 in
                        []
                    }
                }
            }
        }
        
        return Promise { resolve, reject in
            pool.asyncRead { result in
                switch result {
                case .failure(let error):
                    reject(error)
                case .success(let db):
                    do {
                        let messages = try RawMessage
                            .select(RawMessage.Columns.guid, as: String.self)
                            .filter(guids.contains(RawMessage.Columns.associated_message_guid))
                            .fetchAll(db)
                        
                        Message.messages(withGUIDs: messages, in: chat).map {
                            $0.reduce(into: [String: [Message]]()) { ledger, message in
                                guard let associatedMessageGUID = message.associatedMessageID else { return }
                                if ledger[associatedMessageGUID] == nil { ledger[associatedMessageGUID] = [] }
                                ledger[associatedMessageGUID]!.append(message)
                            }
                        }.pipe(resolve, reject)
                    } catch {
                        reject(error)
                    }
                }
            }
        }
    }
    
    /// Resolves associated messages with the given GUID
    /// - Parameter guid: GUID of the message to load associations
    /// - Returns: array of Messages
    func associatedMessages(with guid: String) -> Promise<[Message], Error> {
        Promise { resolve, reject in
            pool.asyncRead { result in
                switch result {
                case .failure(let error):
                    reject(error)
                    return
                case .success(let db):
                    do {
                        let messages = try RawMessage
                            .select(RawMessage.Columns.guid, RawMessage.Columns.ROWID)
                            .filter(sql: "associated_message_guid = ?", arguments: [guid])
                            .fetchAll(db)
                        
                        Message.messages(withGUIDs: messages.map { $0.guid! }).pipe(resolve, reject)
                    } catch {
                        print("Failed to resolve chat group IDs for messages with error \(error)")
                        resolve([])
                        return
                    }
                }
            }
        }
    }
}
