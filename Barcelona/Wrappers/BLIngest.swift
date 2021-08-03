//
//  FulfillMessageObjects.swift
//  Barcelona
//
//  Created by Eric Rabil on 7/25/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import BarcelonaFoundation

private let BLIngestObjectsLog = Logger(category: "BLIngestObjects")

// MARK: - Public API
public func BLIngestObjects(_ objects: [NSObject], inChat chat: String? = nil) -> Promise<[ChatItem]> {
    guard objects.count > 0 else {
        BLIngestObjectsLog.debug("Early-exit BLIngest because objects is empty")
        return .success([])
    }
    
    guard let chat = chat else {
        BLIngestObjectsLog.debug("inferring chat ids before ingestion because chat id was not provided")
        
        return _BLResolveChatIDs(forObjects: objects)
            .then { chatIDs -> Promise<[ChatItem]> in
                BLIngestObjectsLog.debug("got %d chat IDs from database", chatIDs.count)
                
                if _fastPath(chatIDs.allSatisfy { $0 == chatIDs.first }) {
                    BLIngestObjectsLog.debug("taking fast-path for inferred chat IDs because they're all the same (%@)", chatIDs.first!)
                    
                    return BLIngestObjects(objects, inChat: chatIDs.first!)
                }
                
                BLIngestObjectsLog.debug("found mismatched identifiers, ingesting them in chunks (%@)", chatIDs.joined(separator: ", "))
                
                // Loads file transfers in one batch to reduce database calls
                return _BLLoadFileTransfers(forObjects: objects).observeFailure { error in
                    BLIngestObjectsLog.error("failed to load file transfers: %@", error as NSError)
                }.then {
                    Promise.all(objects.enumerated().map { index, object in
                        BLIngestObject(object, inChat: chatIDs[index])
                    })
                }.observeOutput { items in
                    BLIngestObjectsLog.info("aggregated ingestion got %d items", items.count)
                }
            }
    }
    
    return _BLLoadFileTransfers(forObjects: objects).then { () -> [ChatItem] in
        BLIngestObjectsLog.debug("file transfers loaded. parsing objects")
        return _BLParseObjects(objects, inChat: chat)
    }.then { items -> Promise<[ChatItem]> in
        BLIngestObjectsLog.debug("objects parsed. loading tapbacks")
        return _BLLoadTapbacks(forItems: items, inChat: chat)
    }.observeOutput { items in
        BLIngestObjectsLog.info("ingested %d items", items.count)
    }
}

public func BLIngestObject(_ object: NSObject, inChat chat: String? = nil) -> Promise<ChatItem> {
    guard let chat = chat else {
        return _BLResolveChatID(forObject: object)
            .then { chat in
                BLIngestObject(object, inChat: chat)
            }
    }
    
    return BLIngestObjects([object], inChat: chat).then {
        $0.first!
    }
}
