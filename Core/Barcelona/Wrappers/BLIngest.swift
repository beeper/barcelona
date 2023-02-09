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
@MainActor
public func BLIngestObjects(_ objects: [NSObject], inChat chatId: String? = nil, service: IMServiceStyle) -> Promise<[ChatItem]> {
    guard objects.count > 0 else {
        *log.debug("Early-exit BLIngest because objects is empty")
        return .success([])
    }
    
    guard let chatId else {
        *log.debug("inferring chat ids before ingestion because chat id was not provided")
        
        return _BLResolveChatIDs(forObjects: objects)
            .then { chatIDs -> Promise<[ChatItem]> in
                *log.debug("got \(chatIDs.count) chat IDs from database")
                
                if _fastPath(chatIDs.allSatisfy { $0 == chatIDs.first }) {
                    *log.debug("taking fast-path for inferred chat IDs because they're all the same (\(chatIDs.first ?? "")")
                    
                    return BLIngestObjects(objects, inChat: chatIDs.first, service: service)
                }
                
                *log.debug("found mismatched identifiers, ingesting them in chunks (\(chatIDs.joined(separator: ", "))")
                
                // Loads file transfers in one batch to reduce database calls
                return _BLLoadFileTransfers(forObjects: objects).observeFailure { error in
                    *log.error("failed to load file transfers: \(error as NSError)")
                }.then {
                    Promise.all(objects.enumerated().map { index, object in
                        BLIngestObject(object, inChat: chatIDs[index], service: service)
                    })
                }.observeOutput { items in
                    *log.info("aggregated ingestion got \(items.count) items")
                }
            }
    }
    
    return _BLLoadFileTransfers(forObjects: objects).then { () -> [ChatItem] in
        *log.debug("file transfers loaded. parsing objects")
        return _BLParseObjects(objects, inChat: chatId, service: service)
    }.then { items -> Promise<[ChatItem]> in
        *log.debug("objects parsed. loading tapbacks")
        return _BLLoadTapbacks(forItems: items, inChat: chatId, service: service)
    }.observeOutput { items in
        *log.info("ingested \(items.count) items")
    }
}

@MainActor
public func BLIngestObject(_ object: NSObject, inChat chatId: String? = nil, service: IMServiceStyle) -> Promise<ChatItem> {
    guard let chatId else {
        return _BLResolveChatID(forObject: object)
            .then { chatId in
                BLIngestObject(object, inChat: chatId, service: service)
            }
    }
    
    return BLIngestObjects([object], inChat: chatId, service: service).then {
        $0.first!
    }
}
