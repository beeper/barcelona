//
//  DBReader+SearchMessages-Complex.swift
//  Barcelona
//
//  Created by Eric Rabil on 7/30/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import BarcelonaFoundation
import Foundation
import GRDB
import Logging

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

extension DBReader {
    public var log: Logging.Logger {
        Logger(label: "DBReader")
    }
    public func queryMessages(
        withParameters params: MessageQueryParameters,
        handleProvider: IMCNHandleBridgingProvider? = nil
    ) async throws -> [(chatID: String, messageID: String)] {
        let limit = params.limit ?? 20

        let ROWIDs: [Int64]

        if let chatIdentifiers = params.chats {
            ROWIDs = try await rowIDs(forIdentifiers: chatIdentifiers).values.flatten()
        } else {
            ROWIDs = []
        }

        var handles = params.handles ?? []

        #if canImport(IMCore)
        let handleProvider = Optional(handleProvider ?? IMHandleRegistrar.sharedInstance())
        #endif

        /// Get database handle
        let items = try await self.read { db in
            #if DEBUG
            log.info(
                "Performing message query with chat identifiers \(params.chats ?? []) handles \(handles) text \(params.search ?? "<<no search>>") limit \(params.limit ?? 20)"
            )
            #endif

            /// Performs a query for either me or not me (IMCore handle that are associated with an account function differently)
            let query: ([String]?, Bool?) throws -> [RawMessage] = { handles, fromMe in
                var dbQuery =
                    RawMessage
                    .joiningOnROWIDsWhenNotEmpty(ROWIDs: ROWIDs, withColumns: [.guid, .ROWID, .date])

                if let handles = handles, let fromMe = fromMe {
                    dbQuery =
                        dbQuery
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

        /// Preload all the chat identifiers in bulk to reduce overhead later
        let chatIdentifiers = try await chatIdentifiers(forMessageRowIDs: items.map(\.ROWID))

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
