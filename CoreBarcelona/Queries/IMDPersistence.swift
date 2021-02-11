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


/// Parses an array of IMDMessageRecordRef
/// - Parameters:
///   - refs: the refs to parse
///   - chat: the ID of the chat the messages reside in. if omitted, the chat ID will be resolved at ingestion
/// - Returns: An NIO future of ChatItems
private func ERParseIMDMessageRecordRefs(_ refs: NSArray, in chat: String? = nil) -> EventLoopFuture<[ChatItem]> {
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


/// Loads an array of IMDMessageRecordRefs from IMDPersistence
/// - Parameter guids: guids of the messages to load
/// - Returns: an array of the IMDMessageRecordRefs
private func ERLoadIMDMessageRecordRefsWithGUIDs(_ guids: [String]) -> NSArray {
    guard let results = IMDMessageRecordCopyMessagesForGUIDs(guids) else {
        return []
    }
    
    return results as NSArray
}


/// Performs an advanced query of messages with the given parameters
/// - Parameters:
///   - chatIdentifier: identifier of the chat to load messages from
///   - services: chat services to load messages from
///   - beforeGUID: GUID of the message all messages must precede
///   - limit: max number of messages to return
/// - Returns: array of IMDMessageRecordRefs
private func ERLoadIMDMessageRecordRefs(withChatIdentifier chatIdentifier: String, onServices services: [IMServiceStyle] = [], beforeGUID: String? = nil, limit: Int64) -> NSArray {
    guard let records = IMDMessageRecordCopyMessagesWithChatIdentifiersOnServicesUpToGUIDOrLimitWithOptionalThreadIdentifier([chatIdentifier] as CFArray, services.map { $0.rawValue } as CFArray, beforeGUID as CFString?, nil, true, false, limit) else {
        return [] as NSArray
    }
    
    return records as NSArray
}


/// Resolves ChatItems with the given GUIDs
/// - Parameters:
///   - guids: GUIDs of messages to load
///   - chat: ID of the chat to load. if omitted, it will be resolved at ingestion.
/// - Returns: NIO futuer of ChatItems
internal func ERLoadAndParseIMDMessageRecordRefsWithGUIDs(_ guids: [String], in chat: String? = nil) -> EventLoopFuture<[ChatItem]> {
    let refs = ERLoadIMDMessageRecordRefsWithGUIDs(guids)
    
    return ERParseIMDMessageRecordRefs(refs, in: chat)
}


/// Resolves ChatItems with the given parameters
/// - Parameters:
///   - chatIdentifier: identifier of the chat to load messages from
///   - services: chat services to load messages from
///   - beforeGUID: GUID of the message all messages must precede
///   - limit: max number of messages to return
/// - Returns: NIO future of ChatItems
internal func ERLoadAndParseIMDMessageRecordRefs(withChatIdentifier chatIdentifier: String, onServices services: [IMServiceStyle] = [], beforeGUID: String? = nil, limit: Int64? = nil) -> EventLoopFuture<[ChatItem]> {
    let refs = ERLoadIMDMessageRecordRefs(withChatIdentifier: chatIdentifier, onServices: services, beforeGUID: beforeGUID, limit: limit ?? ERDefaultMessageQueryLimit)
    
    return ERParseIMDMessageRecordRefs(refs, in: chatIdentifier)
}
