//
//  DBReader+SearchMessages-Complex.swift
//  Barcelona
//
//  Created by Eric Rabil on 7/30/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import BarcelonaFoundation
import GRDB

public protocol IMCNHandleBridgingProvider {
    func handleIDs(forCNIdentifier arg1: String) -> [String]
    var allLoginHandles: [String] { get }
}

#if canImport(IMCore)
import IMCore

extension IMHandleRegistrar: IMCNHandleBridgingProvider {
    public func handleIDs(forCNIdentifier arg1: String) -> [String] {
        handles(forCNIdentifier: arg1).map(\.id)
    }
    
    public var allLoginHandles: [String] {
        IMAccountController.__sharedInstance().accounts.flatMap(\.aliases)
    }
}
#endif

public extension DBReader {
    func queryMessages(withParameters params: MessageQueryParameters, handleProvider: IMCNHandleBridgingProvider? = nil) -> Promise<[(chatID: String, messageID: String)]> {
        let limit = params.limit ?? 20
        
        var chatRowIDQuery: Promise<[Int64]>
        
        if let chatIdentifiers = params.chats {
            chatRowIDQuery = self.rowIDs(forIdentifiers: chatIdentifiers).values.flatten()
        } else {
            chatRowIDQuery = .success([])
        }
        
        var handles = params.handles ?? []
        
        #if canImport(IMCore)
        let handleProvider = Optional(handleProvider ?? IMHandleRegistrar.sharedInstance())
        #endif
        
        /// Resolve the ROWIDs of any provided chat identifiers
        return chatRowIDQuery.then { ROWIDs -> Promise<ArraySlice<RawMessage>> in
            /// Get database handle
            self.read { db in
                #if DEBUG
                DBLog("Performing message query with chat identifiers %@ handles %@ text %@ limit %ld", params.chats ?? [], handles, params.search ?? "<<no search>>", params.limit ?? 20)
                #endif
                
                /// Performs a query for either me or not me (IMCore handle that are associated with an account function differently)
                let query: ([String]?, Bool?) throws -> [RawMessage] = { handles, fromMe in
                    var dbQuery = RawMessage
                        .joiningOnROWIDsWhenNotEmpty(ROWIDs: ROWIDs, withColumns: [.guid, .ROWID, .date])
                    
                    if let handles = handles, let fromMe = fromMe {
                        dbQuery = dbQuery
                            .joiningOnHandlesWhenNotEmpty(handles: handles)
                            .filter(RawMessage.Columns.is_from_me == (fromMe ? 1 : 0))
                    }
                    
                    return try dbQuery.filterTextWhenNotEmpty(text: params.search)
                        .filterBundleIDWhenNotEmpty(bundleID: params.bundle_id)
                        .order(RawMessage.Columns.date.desc)
                        .limit(limit)
                        .fetchAll(db)
                }
                
                let allLoginHandles = handleProvider?.allLoginHandles ?? []
                
                let loginHandles = handles.filter { allLoginHandles.contains($0) }
                let otherHandles = handles.filter { !allLoginHandles.contains($0) }
                
                var messagesFromMe: [RawMessage]!
                
                /// Only do a split query when handles are provided
                if loginHandles.count > 0 || otherHandles.count > 0 {
                    messagesFromMe = loginHandles.count > 0 ? try query(loginHandles, true) : []
                    messagesFromMe.append(contentsOf: otherHandles.count > 0 ? try query(otherHandles, false) : [])
                } else {
                    messagesFromMe = try query(nil, nil)
                }
                
                messagesFromMe.sort(by: { m1, m2 in
                    (m1.date ?? 0) > (m2.date ?? 0)
                })
                
                return messagesFromMe.prefix(limit)
            }
        }.then { items -> Promise<([Int64: String], ArraySlice<RawMessage>)> in
            /// Preload all the chat identifiers in bulk to reduce overhead later
            self.chatIdentifiers(forMessageRowIDs: items.map(\.ROWID)).then {
                ($0, items)
            }
        }.then { chatIdentifiers, items -> [(chatID: String, messageID: String)] in
            var masterMap: [String: [String]] = [:]
            let messageROWIDtoGUID = items.compactDictionary(keyedBy: \.ROWID, valuedBy: \.guid)
            
            /// Sort the results into a dictionary of <Chat Identifier, [Message GUID]>
            chatIdentifiers.forEach {
                guard let guid = messageROWIDtoGUID[$0.key] else {
                    return
                }
                
                if masterMap[$0.value] == nil {
                    masterMap[$0.value] = []
                }
                
                masterMap[$0.value]!.append(guid)
            }
            
            /// Take each chunk of chat<->messages and resolve them
            return masterMap.flatMap { chatID, messageIDs in
                messageIDs.map {
                    (chatID, $0)
                }
            }
        }
    }
}
