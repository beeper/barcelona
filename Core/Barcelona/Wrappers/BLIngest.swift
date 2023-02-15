//
//  FulfillMessageObjects.swift
//  Barcelona
//
//  Created by Eric Rabil on 7/25/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import BarcelonaFoundation
import Logging

private let log = Logger(label: "BLIngestObjects")

// MARK: - Public API
public func BLIngestObjects(_ objects: [NSObject], inChat chatId: String? = nil, service: IMServiceStyle) async throws -> [ChatItem] {
    guard objects.count > 0 else {
        *log.debug("Early-exit BLIngest because objects is empty")
        return []
    }
    
    guard let chatId else {
        *log.debug("inferring chat ids before ingestion because chat id was not provided")
        
        let chatIDs = try await _BLResolveChatIDs(forObjects: objects)

        *log.debug("got \(chatIDs.count) chat IDs from database")

        if _fastPath(chatIDs.allSatisfy { $0 == chatIDs.first }) {
            *log.debug("taking fast-path for inferred chat IDs because they're all the same (\(chatIDs.first ?? "")")

            return try await BLIngestObjects(objects, inChat: chatIDs.first, service: service)
        }

        *log.debug("found mismatched identifiers, ingesting them in chunks (\(chatIDs.joined(separator: ", "))")

        // Loads file transfers in one batch to reduce database calls
        do {
            try await _BLLoadFileTransfers(forObjects: objects)
        } catch {
            *log.error("failed to load file transfers: \(error as NSError)")
        }

        let items = try await withThrowingTaskGroup(of: ChatItem.self, returning: [ChatItem].self) { group in
            for (index, object) in objects.enumerated() {
                group.addTask {
                    return try await BLIngestObject(object, inChat: chatIDs[index], service: service)
                }
            }

            return try await group.reduce(into: []) { $0.append($1) }
        }

        *log.info("aggregated ingestion got \(items.count) items")

        return items
    }
    
    try await _BLLoadFileTransfers(forObjects: objects)

    *log.debug("file transfers loaded. parsing objects")
    let items = _BLParseObjects(objects, inChat: chatId, service: service)

    *log.debug("objects parsed. loading tapbacks")
    let tapbacks = try await _BLLoadTapbacks(forItems: items, inChat: chatId, service: service)

    *log.info("ingested \(tapbacks.count) items")
    return tapbacks
}

public func BLIngestObject(_ object: NSObject, inChat chatId: String? = nil, service: IMServiceStyle) async throws -> ChatItem {
    guard let chatId else {
        let chatId = try await _BLResolveChatID(forObject: object)
        return try await BLIngestObject(object, inChat: chatId, service: service)
    }
    
    return try await BLIngestObjects([object], inChat: chatId, service: service).first!
}
