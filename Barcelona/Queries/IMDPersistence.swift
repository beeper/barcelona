//
//  IMDPersistence.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 1/29/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import IMDPersistence
import IMCore
import os.log

internal func ERCreateIMItemFromIMDMessageRecordRefsSynchronously(_ refs: NSArray) -> [IMItem] {
    return refs.compactMap {
        IMDCreateIMItemFromIMDMessageRecordRefWithServiceResolve($0, nil, nil, nil, nil)
    }
}

internal func ERCreateIMItemFromIMDMessageRecordRefs(_ refs: NSArray) -> Promise<[IMItem], Error> {
    return Promise { resolve in
        resolve(ERCreateIMItemFromIMDMessageRecordRefsSynchronously(refs))
    }
}

internal func ERConvertIMDMessageRecordRefsToIMMessage(_ refs: NSArray) -> Promise<[IMMessage], Error> {
    return ERCreateIMItemFromIMDMessageRecordRefs(refs).then {
        $0.compactMap {
            $0 as? IMMessageItem
        }.compactMap {
            IMMessage.message(fromUnloadedItem: $0)
        }
    }
}

/// Parses an array of IMDMessageRecordRef
/// - Parameters:
///   - refs: the refs to parse
///   - chat: the ID of the chat the messages reside in. if omitted, the chat ID will be resolved at ingestion
/// - Returns: An NIO future of ChatItems
internal func ERParseIMDMessageRecordRefs(_ refs: NSArray, in chat: String? = nil) -> Promise<[ChatItem], Error> {
    return ERCreateIMItemFromIMDMessageRecordRefs(refs).then { items -> Promise<[ChatItem], Error> in
        os_log("Ingesting chat items")
        
        return BLIngestObjects(items, inChat: chat)
    }
}

internal func ERResolveGUIDsForChat(withChatIdentifier chatIdentifier: String, beforeDate date: Date? = nil, beforeGUID: String? = nil, limit: Int? = nil) -> Promise<[String], Error> {
    DBReader.shared.rowIDs(forIdentifier: chatIdentifier).flatMap { ROWIDs in
        DBReader.shared.newestMessageGUIDs(inChatROWIDs: ROWIDs, beforeDate: date, beforeMessageGUID: beforeGUID, limit: limit)
    }
}


/// Loads an array of IMDMessageRecordRefs from IMDPersistence
/// - Parameter guids: guids of the messages to load
/// - Returns: an array of the IMDMessageRecordRefs
internal func ERLoadIMDMessageRecordRefsWithGUIDs(_ guids: [String]) -> NSArray {
    guard let results = IMDMessageRecordCopyMessagesForGUIDs(guids) else {
        return []
    }
    
    return results as NSArray
}

internal func ERLoadIMItemsWithGUIDs(_ guids: [String]) -> [IMItem] {
    let refs = ERLoadIMDMessageRecordRefsWithGUIDs(guids)
    
    return ERCreateIMItemFromIMDMessageRecordRefsSynchronously(refs)
}

internal func ERLoadIMItemWithGUID(_ guid: String) -> IMItem? {
    ERLoadIMItemsWithGUIDs([guid]).first
}

internal func ERLoadIMMessagesWithGUIDs(_ guids: [String]) -> Promise<[IMMessage], Error> {
    let refs = ERLoadIMDMessageRecordRefsWithGUIDs(guids)
    
    return ERConvertIMDMessageRecordRefsToIMMessage(refs)
}

/// Resolves ChatItems with the given GUIDs
/// - Parameters:
///   - guids: GUIDs of messages to load
///   - chat: ID of the chat to load. if omitted, it will be resolved at ingestion.
/// - Returns: NIO futuer of ChatItems
internal func ERLoadAndParseIMDMessageRecordRefsWithGUIDs(_ guids: [String], in chat: String? = nil) -> Promise<[ChatItem], Error> {
    let refs = ERLoadIMDMessageRecordRefsWithGUIDs(guids)
    
    return ERParseIMDMessageRecordRefs(refs, in: chat)
}

internal func ERLoadIMMessages(withChatIdentifier chatIdentifier: String, onServices services: [IMServiceStyle] = [], beforeGUID: String? = nil, limit: Int? = nil) -> Promise<[IMMessage], Error> {
    ERResolveGUIDsForChat(withChatIdentifier: chatIdentifier, beforeGUID: beforeGUID, limit: limit).then {
        ERLoadIMMessagesWithGUIDs($0)
    }
}

/// Resolves ChatItems with the given parameters
/// - Parameters:
///   - chatIdentifier: identifier of the chat to load messages from
///   - services: chat services to load messages from
///   - beforeGUID: GUID of the message all messages must precede
///   - limit: max number of messages to return
/// - Returns: NIO future of ChatItems
public func CBLoadChatItems(withChatIdentifier chatIdentifier: String, onServices services: [IMServiceStyle] = [], beforeDate date: Date? = nil, beforeGUID: String? = nil, limit: Int? = nil) -> Promise<[ChatItem], Error> {
    ERResolveGUIDsForChat(withChatIdentifier: chatIdentifier, beforeDate: date, beforeGUID: beforeGUID, limit: limit).then {
        ERLoadAndParseIMDMessageRecordRefsWithGUIDs($0, in: chatIdentifier)
    }
}

typealias IMFileTransferFromIMDAttachmentRecordRefType = @convention(c) (_ record: Any) -> IMFileTransfer?

private let IMDaemonCore = "/System/Library/PrivateFrameworks/IMDaemonCore.framework/Versions/Current/IMDaemonCore".withCString({
    dlopen($0, RTLD_LAZY)
})!

private let _IMFileTransferFromIMDAttachmentRecordRef = "IMFileTransferFromIMDAttachmentRecordRef".withCString ({ dlsym(IMDaemonCore, $0) })

internal let IMFileTransferFromIMDAttachmentRecordRef = unsafeBitCast(_IMFileTransferFromIMDAttachmentRecordRef, to: IMFileTransferFromIMDAttachmentRecordRefType.self)

public func CBLoadAttachmentPathForTransfer(withGUID guid: String) -> String? {
    guard let attachment = IMDAttachmentRecordCopyAttachmentForGUID(guid as CFString) else {
        return nil
    }
    
    return IMFileTransferFromIMDAttachmentRecordRef(attachment)?.localPath
}
