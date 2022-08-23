//
//  IMDPersistence.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 1/29/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import IMDPersistence
import BarcelonaDB
import IMCore
import IMSharedUtilities
import Pwomise
import Swog

private let IMDLog = Logger(category: "IMDPersistenceQueries")

#if DEBUG
private var IMDWithinBlock = false

private let IMDQueue: DispatchQueue = {
    atexit {
        if IMDWithinBlock {
            IMDLog.warn("IMDPersistence tried to exit! Let's talk about that.")
        }
    }
    
    return DispatchQueue(label: "com.barcelona.IMDPersistence")
}()
#else
private let IMDQueue: DispatchQueue = DispatchQueue(label: "com.barcelona.IMDPersistence")
#endif

@_transparent
private func withinIMDQueue<R>(_ exp: @autoclosure() -> R) -> R {
    #if DEBUG
    IMDQueue.sync {
        IMDWithinBlock = true
        
        defer { IMDWithinBlock = false }
        
        return exp()
    }
    #else
    IMDQueue.sync(execute: exp)
    #endif
}

private let IMDCreateIMItemFromIMDMessageRecordRefWithServiceResolve_imp: (@convention(c) (Any?, Any?, Bool, Any?) -> Unmanaged<IMItem>?)? = CBWeakLink(against: .privateFramework(name: "IMDPersistence"), options: [
    .symbol("IMDCreateIMItemFromIMDMessageRecordRefWithServiceResolve").preMonterey,
    .symbol("IMDCreateIMItemFromIMDMessageRecordRefWithAccountLookup").monterey
])

// MARK: - IMDPersistence
private func BLCreateIMItemFromIMDMessageRecordRefs(_ refs: NSArray) -> [IMItem] {
    guard let IMDCreateIMItemFromIMDMessageRecordRefWithServiceResolve_imp = IMDCreateIMItemFromIMDMessageRecordRefWithServiceResolve_imp else {
        return []
    }
    
    #if DEBUG
    let operation = IMDLog.operation(named: "ERCreateIMItemFromIMDMessageRecordRefs").begin("converting %ld refs", refs.count)
    #endif
    
    if refs.count == 0 {
        #if DEBUG
        operation.end("early-exit, zero refs")
        #endif
        return []
    }
    
    #if DEBUG
    defer {
        operation.end()
    }
    #endif
    
    return refs.compactMap {
        withinIMDQueue(IMDCreateIMItemFromIMDMessageRecordRefWithServiceResolve_imp($0, nil, false, nil))?.takeRetainedValue()
    }
}

/// Loads an array of IMDMessageRecordRefs from IMDPersistence
/// - Parameter guids: guids of the messages to load
/// - Returns: an array of the IMDMessageRecordRefs
private func BLLoadIMDMessageRecordRefsWithGUIDs(_ guids: [String]) -> NSArray {
    let operation = IMDLog.operation(named: "ERLoadIMDMessageRecordRefsWithGUIDs")
    #if DEBUG
    operation.begin("loading %ld guids", guids.count)
    #endif
    
    if guids.count == 0 {
        #if DEBUG
        operation.end("early-exit: 0 guids provided")
        #endif
        return []
    }
    
    guard let results = withinIMDQueue(IMDMessageRecordCopyMessagesForGUIDs(guids as CFArray)) else {
        #if DEBUG
        operation.end("could not copy messages from IMDPersistance. guids: %@", guids)
        #endif
        return []
    }
    
    #if DEBUG
    operation.end("loaded %ld guids", guids.count)
    #endif
    
    return results as NSArray
}

// MARK: - Helpers
private func ERCreateIMMessageFromIMItem(_ items: [IMItem]) -> [IMMessage] {
    #if DEBUG
    let operation = IMDLog.operation(named: "ERConvertIMDMessageRecordRefsToIMMessage").begin("converting %ld IMItems to IMMessage", items.count)
    #endif
    
    guard items.count > 0 else {
        #if DEBUG
        operation.end("early-exit: empty array passed for conversion")
        #endif
        return []
    }
    
    let items = items.compactMap {
        $0 as? IMMessageItem
    }
    
    guard items.count > 0 else {
        #if DEBUG
        operation.end("early-exit: no IMMessageItem found")
        #endif
        return []
    }
    
    let messages = items.compactMap {
        IMMessage.message(fromUnloadedItem: $0)
    }
    
    #if DEBUG
    operation.end("loaded %ld IMMessages from %ld items", messages.count, items.count)
    #endif
    
    return messages
}

private func BLCreateIMMessageFromIMDMessageRecordRefs(_ refs: NSArray) -> [IMMessage] {
    ERCreateIMMessageFromIMItem(BLCreateIMItemFromIMDMessageRecordRefs(refs))
}

// MARK: - Private API

/// Parses an array of IMDMessageRecordRef
/// - Parameters:
///   - refs: the refs to parse
///   - chat: the ID of the chat the messages reside in. if omitted, the chat ID will be resolved at ingestion
/// - Returns: An NIO future of ChatItems
private func BLIngestIMDMessageRecordRefs(_ refs: NSArray, in chat: String? = nil) -> Promise<[ChatItem]> {
    if refs.count == 0 {
        return .success([])
    }
    
    var items = BLCreateIMItemFromIMDMessageRecordRefs(refs)
    
    return BLIngestObjects(items, inChat: chat)
}

internal func ERResolveGUIDsForChats(withChatIdentifiers chatIdentifiers: [String], afterDate: Date? = nil, beforeDate: Date? = nil, afterGUID: String? = nil, beforeGUID: String? = nil, limit: Int? = nil) -> Promise<[(messageID: String, chatID: String)]> {
    #if DEBUG
    let operation = IMDLog.operation(named: "ERResolveGUIDsForChat")
    operation.begin("Resolving GUIDs for chat %@ before time %@ before guid %@ limit %@", chatIdentifiers, (beforeDate?.timeIntervalSince1970 ?? 0).description, beforeGUID ?? "(nil)", (limit ?? -1).description)
    #endif
    
    let result = DBReader.shared.newestMessageGUIDs(forChatIdentifiers: chatIdentifiers, beforeDate: beforeDate, afterDate: afterDate, beforeMessageGUID: beforeGUID, afterMessageGUID: afterGUID, limit: limit)
    #if DEBUG
    result.observeAlways { result in
        switch result {
        case .success(let GUIDs):
            operation.end("Got %ld GUIDs", GUIDs.count)
        case .failure(let error):
            operation.end("Failed to load newest GUIDs: %@", error as NSError)
        }
    }
    #endif
    return result
}

// MARK: - API

public func BLLoadIMMessageItems(withGUIDs guids: [String]) -> [IMMessageItem] {
    if guids.count == 0 {
        return []
    }
    
    return autoreleasepool {
        BLCreateIMItemFromIMDMessageRecordRefs(BLLoadIMDMessageRecordRefsWithGUIDs(guids)).compactMap {
            switch $0 {
            case let item as IMMessageItem:
                return item
            case let unknown:
                return nil
            }
        }
    }
}

public func BLLoadIMMessageItem(withGUID guid: String) -> IMMessageItem? {
    BLLoadIMMessageItems(withGUIDs: [guid]).first
}

public func BLLoadIMMessages(withGUIDs guids: [String]) -> [IMMessage] {
    BLLoadIMMessageItems(withGUIDs: guids).compactMap(IMMessage.message(fromUnloadedItem:))
}

public func BLLoadIMMessage(withGUID guid: String) -> IMMessage? {
    BLLoadIMMessages(withGUIDs: [guid]).first
}

/// Resolves ChatItems with the given GUIDs
/// - Parameters:
///   - guids: GUIDs of messages to load
///   - chat: ID of the chat to load. if omitted, it will be resolved at ingestion.
/// - Returns: NIO future of ChatItems
public func BLLoadChatItems(withGUIDs guids: [String], chatID: String? = nil) -> Promise<[ChatItem]> {
    if guids.count == 0 {
        return .success([])
    }
    
    let (buffer, remaining) = IMDPersistenceMarshal.partialBuffer(guids)

    guard let guids = remaining else {
        return buffer
    }
    
    let refs = BLLoadIMDMessageRecordRefsWithGUIDs(guids)
    
    return IMDPersistenceMarshal.putBuffers(guids, BLIngestIMDMessageRecordRefs(refs, in: chatID)) + buffer
}

public func BLLoadChatItems(withGraph graph: [String: [String]]) -> Promise<[ChatItem]> {
    if graph.count == 0 {
        return .success([])
    }
    
    let guids = graph.flatMap(\.value)
    let (buffer, remaining) = IMDPersistenceMarshal.partialBuffer(guids)
    
    guard let guids = remaining else {
        return buffer
    }
    
    let refs = BLCreateIMItemFromIMDMessageRecordRefs(BLLoadIMDMessageRecordRefsWithGUIDs(guids))
    let items = refs.dictionary(keyedBy: \.id)
    
    let pendingIngestion = Promise.all(graph.mapValues { guids in
        guids.compactMap { items[$0] }
    }.map { chatID, items -> Promise<[ChatItem]> in
        BLIngestObjects(items, inChat: chatID)
    }).flatten()
    
    return IMDPersistenceMarshal.putBuffers(guids, pendingIngestion) + buffer
}

/// Resolves ChatItems with the given parameters
/// - Parameters:
///   - chatIdentifier: identifier of the chat to load messages from
///   - services: chat services to load messages from
///   - beforeGUID: GUID of the message all messages must precede
///   - limit: max number of messages to return
/// - Returns: NIO future of ChatItems
public func BLLoadChatItems(withChatIdentifiers chatIdentifiers: [String], onServices services: [IMServiceStyle] = [], afterDate: Date? = nil, beforeDate: Date? = nil, afterGUID: String? = nil, beforeGUID: String? = nil, limit: Int? = nil) -> Promise<[ChatItem]> {
    ERResolveGUIDsForChats(withChatIdentifiers: chatIdentifiers, afterDate: afterDate, beforeDate: beforeDate, afterGUID: afterGUID, beforeGUID: beforeGUID, limit: limit).then {
        BLLoadChatItems(withGraph: $0.collectedDictionary(keyedBy: \.chatID, valuedBy: \.messageID))
    }
}

typealias IMFileTransferFromIMDAttachmentRecordRefType = @convention(c) (_ record: Any) -> IMFileTransfer?

private let IMDaemonCore = "/System/Library/PrivateFrameworks/IMDaemonCore.framework/IMDaemonCore".withCString({
    dlopen($0, RTLD_LAZY)
})!

private let _IMFileTransferFromIMDAttachmentRecordRef = "IMFileTransferFromIMDAttachmentRecordRef".withCString ({ dlsym(IMDaemonCore, $0) })
private let IMFileTransferFromIMDAttachmentRecordRef = unsafeBitCast(_IMFileTransferFromIMDAttachmentRecordRef, to: IMFileTransferFromIMDAttachmentRecordRefType.self)

public func BLLoadFileTransfer(withGUID guid: String) -> IMFileTransfer? {
    guard let attachment = IMDAttachmentRecordCopyAttachmentForGUID(guid as CFString) else {
        return nil
    }
    
    return IMFileTransferFromIMDAttachmentRecordRef(attachment)
}

public func BLLoadAttachmentPathForTransfer(withGUID guid: String) -> String? {
    BLLoadFileTransfer(withGUID: guid)?.localPath
}
