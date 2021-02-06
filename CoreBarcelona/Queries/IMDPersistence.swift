//
//  IMDPersistence.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 1/29/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import IMDPersistence
import NIO
import os.log

internal func CFRelease(_ object: AnyObject) {
    Unmanaged.passUnretained(object).release()
}

internal func CFRetain(_ object: AnyObject) {
    Unmanaged.passUnretained(object).retain()
}

internal func ERParseIMDMessageRecordRefs(_ refs: NSArray, in chat: String? = nil) -> EventLoopFuture<[ChatItem]> {
    return messageQuerySystem.next().submit {
        return (refs as NSArray).compactMap {
            IMDCreateIMItemFromIMDMessageRecordRefWithServiceResolve($0, nil, nil, nil, nil)
        }
    }.flatMap { items -> EventLoopFuture<[ChatItem]> in
        os_log("Ingesting chat items")
        
        let ingestion = ERIndeterminateIngestor.ingest(items, in: chat)
        
        ingestion.whenSuccess { _ in
            items.forEach(CFRelease(_:))
        }
        
        return ingestion
    }
}

private func ERLoadIMDMessageRecordRefsWithGUIDs(_ guids: [String]) -> NSArray {
    guard let results = IMDMessageRecordCopyMessagesForGUIDs(guids) else {
        return []
    }
    
    return results as NSArray
}

private func ERLoadIMDMessageRecordRefs(withChatIdentifier chatIdentifier: String, onServices services: [IMServiceStyle] = [], beforeGUID: String? = nil, limit: Int64) -> NSArray {
    guard let records = IMDMessageRecordCopyMessagesWithChatIdentifiersOnServicesUpToGUIDOrLimitWithOptionalThreadIdentifier([chatIdentifier] as CFArray, services.map { $0.rawValue } as CFArray, beforeGUID as CFString?, nil, true, false, limit) else {
        return [] as NSArray
    }
    
    return records as NSArray
}

internal func ERLoadAndParseIMDMessageRecordRefsWithGUIDs(_ guids: [String], in chat: String? = nil) -> EventLoopFuture<[ChatItem]> {
    let refs = ERLoadIMDMessageRecordRefsWithGUIDs(guids)
    
    return ERParseIMDMessageRecordRefs(refs, in: chat)
}

internal func ERLoadAndParseIMDMessageRecordRefs(withChatIdentifier chatIdentifier: String, onServices services: [IMServiceStyle] = [], beforeGUID: String? = nil, limit: Int64? = nil) -> EventLoopFuture<[ChatItem]> {
    let refs = ERLoadIMDMessageRecordRefs(withChatIdentifier: chatIdentifier, onServices: services, beforeGUID: beforeGUID, limit: limit ?? ERDefaultMessageQueryLimit)
    
    return ERParseIMDMessageRecordRefs(refs, in: chatIdentifier)
}
