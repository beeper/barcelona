//
//  IMDPersistence.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 1/29/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import BarcelonaDB
import Combine
import Foundation
import IMCore
import IMDPersistence
import IMSharedUtilities
import Logging

private let log = Logger(label: "IMDPersistenceQueries")

#if DEBUG
private var IMDWithinBlock = false

private let IMDQueue: DispatchQueue = {
    atexit {
        if IMDWithinBlock {
            log.warning("IMDPersistence tried to exit! Let's talk about that.")
        }
    }

    return DispatchQueue(label: "com.barcelona.IMDPersistence")
}()
#else
private let IMDQueue: DispatchQueue = DispatchQueue(label: "com.barcelona.IMDPersistence")
#endif

@_transparent
private func withinIMDQueue<R>(_ exp: @autoclosure () -> R) -> R {
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

private let IMDCreateIMItemFromIMDMessageRecordRefWithServiceResolve_imp:
    (@convention(c) (Any?, Any?, Bool, Any?) -> Unmanaged<IMItem>?)? = CBWeakLink(
        against: .privateFramework(name: "IMDPersistence"),
        options: [
            .symbol("IMDCreateIMItemFromIMDMessageRecordRefWithServiceResolve").preMonterey,
            .symbol("IMDCreateIMItemFromIMDMessageRecordRefWithAccountLookup").monterey,
        ]
    )

// MARK: - IMDPersistence
private func BLCreateIMItemFromIMDMessageRecordRefs(_ refs: NSArray) -> [IMItem] {
    guard
        let IMDCreateIMItemFromIMDMessageRecordRefWithServiceResolve_imp =
            IMDCreateIMItemFromIMDMessageRecordRefWithServiceResolve_imp
    else {
        return []
    }

    #if DEBUG
    log.debug("converting \(refs.count) refs")
    #endif

    if refs.count == 0 {
        #if DEBUG
        log.debug("early-exit, zero refs")
        #endif
        return []
    }

    return refs.compactMap {
        withinIMDQueue(IMDCreateIMItemFromIMDMessageRecordRefWithServiceResolve_imp($0, nil, false, nil))?
            .takeRetainedValue()
    }
}

/// Loads an array of IMDMessageRecordRefs from IMDPersistence
/// - Parameter guids: guids of the messages to load
/// - Returns: an array of the IMDMessageRecordRefs
private func BLLoadIMDMessageRecordRefsWithGUIDs(_ guids: [String]) -> NSArray {
    #if DEBUG
    log.debug("loading \(guids.count) guids")
    #endif

    if guids.count == 0 {
        #if DEBUG
        log.debug("early-exit: 0 guids provided")
        #endif
        return []
    }

    guard let results = withinIMDQueue(IMDMessageRecordCopyMessagesForGUIDs(guids as CFArray)) else {
        #if DEBUG
        log.debug("could not copy messages from IMDPersistance. guids: \(guids)")
        #endif
        return []
    }

    #if DEBUG
    log.debug("loaded \(guids.count) guids")
    #endif

    return results as NSArray
}

// MARK: - Helpers
private func ERCreateIMMessageFromIMItem(_ items: [IMItem]) -> [IMMessage] {
    #if DEBUG
    log.debug("converting \(items.count) IMItems to IMMessage")
    #endif

    guard items.count > 0 else {
        #if DEBUG
        log.debug("early-exit: empty array passed for conversion")
        #endif
        return []
    }

    let items = items.compactMap {
        $0 as? IMMessageItem
    }

    guard items.count > 0 else {
        #if DEBUG
        log.debug("early-exit: no IMMessageItem found")
        #endif
        return []
    }

    let messages = items.compactMap {
        IMMessage.message(fromUnloadedItem: $0)
    }

    #if DEBUG
    log.debug("loaded \(messages.count) IMMessages from \(items.count) items")
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
/// - Returns: The `ChatItem`s representing the ingested refs
private func BLIngestIMDMessageRecordRefs(
    _ refs: NSArray,
    in chat: String? = nil,
    service: IMServiceStyle
) async throws -> [ChatItem] {
    if refs.count == 0 {
        return []
    }

    let items = BLCreateIMItemFromIMDMessageRecordRefs(refs)

    return try await BLIngestObjects(items, inChat: chat, service: service)
}

internal func ERResolveGUIDsForChats(
    withChatIdentifiers chatIdentifiers: [String],
    afterDate: Date? = nil,
    beforeDate: Date? = nil,
    afterGUID: String? = nil,
    beforeGUID: String? = nil,
    limit: Int? = nil
) async throws -> [(messageID: String, chatID: String)] {
    #if DEBUG
    log.debug(
        "Resolving GUIDs for chat \(chatIdentifiers) before time \((beforeDate?.timeIntervalSince1970 ?? 0).description) before guid \( beforeGUID ?? "(nil)") limit \((limit ?? -1).description)"
    )
    #endif

    do {
        let guids = try await DBReader.shared.newestMessageGUIDs(
            forChatIdentifiers: chatIdentifiers,
            beforeDate: beforeDate,
            afterDate: afterDate,
            beforeMessageGUID: beforeGUID,
            afterMessageGUID: afterGUID,
            limit: limit
        )
        #if DEBUG
        log.debug("Got \(guids.count) GUIDs")
        #endif
        return guids
    } catch {
        log.debug("Failed to load newest GUIDs: \(error as NSError)")
        throw error
    }
}

// MARK: - API

func BLLoadIMMessageItems(withGUIDs guids: [String]) -> [IMMessageItem] {
    if guids.count == 0 {
        return []
    }

    return autoreleasepool {
        BLCreateIMItemFromIMDMessageRecordRefs(BLLoadIMDMessageRecordRefsWithGUIDs(guids))
            .compactMap {
                $0 as? IMMessageItem
            }
    }
}

func BLLoadIMMessageItem(withGUID guid: String) -> IMMessageItem? {
    BLLoadIMMessageItems(withGUIDs: [guid]).first
}

@usableFromInline
func BLLoadIMMessages(withGUIDs guids: [String]) -> [IMMessage] {
    BLLoadIMMessageItems(withGUIDs: guids).compactMap(IMMessage.message(fromUnloadedItem:))
}

public func BLLoadIMMessage(withGUID guid: String) -> IMMessage? {
    BLLoadIMMessages(withGUIDs: [guid]).first
}

/// Resolves ChatItems with the given GUIDs
/// - Parameters:
///   - guids: GUIDs of messages to load
///   - chat: ID of the chat to load. if omitted, it will be resolved at ingestion.
/// - Returns: The requested `ChatItem`s
public func BLLoadChatItems(
    withGUIDs guids: [String],
    chatID: String? = nil,
    service: IMServiceStyle
) async throws -> [ChatItem] {
    if guids.count == 0 {
        return []
    }

    let (buffer, remaining) = IMDPersistenceMarshal.partialBuffer(guids)

    guard let guids = remaining else {
        return await buffer.value
    }

    let refs = BLLoadIMDMessageRecordRefsWithGUIDs(guids)

    let ingestFut = Task<[ChatItem], Never> {
        (try? await BLIngestIMDMessageRecordRefs(refs, in: chatID, service: service)) ?? []
    }

    IMDPersistenceMarshal.putBuffers(guids, ingestFut)

    let buffers = await ingestFut.value
    let bufVal = await buffer.value

    return buffers + bufVal
}

func BLLoadChatItems(withGraph graph: [String: ([String], IMServiceStyle)]) async throws -> [ChatItem] {
    if graph.count == 0 {
        return []
    }

    let guids = graph.values.flatMap(\.0)
    let (buffer, remaining) = IMDPersistenceMarshal.partialBuffer(guids)

    guard let guids = remaining else {
        return await buffer.value
    }

    let refs = BLCreateIMItemFromIMDMessageRecordRefs(BLLoadIMDMessageRecordRefsWithGUIDs(guids))
    let items = refs.dictionary(keyedBy: \.id)

    let values = graph.mapValues { (guids, service) in
        (guids.compactMap { items[$0] }, service)
    }

    let pendingIngestion = Task<[ChatItem], Never> {
        let results: [ChatItem] =
            await values.asyncMap {
                let (chatID, (items, service)) = $0
                return (try? await BLIngestObjects(items, inChat: chatID, service: service)) ?? []
            }
            .flatten()

        return results
    }

    IMDPersistenceMarshal.putBuffers(guids, pendingIngestion)

    return (await pendingIngestion.value) + (await buffer.value)
}

/// Resolves ChatItems with the given parameters
/// - Parameters:
///   - chatIdentifier: identifier of the chat to load messages from
///   - services: chat services to load messages from
///   - beforeGUID: GUID of the message all messages must precede
///   - limit: max number of messages to return
/// - Returns: The requested `ChatItem`s
public func BLLoadChatItems(
    withChats chats: [(id: String, service: IMServiceStyle)],
    afterDate: Date? = nil,
    beforeDate: Date? = nil,
    afterGUID: String? = nil,
    beforeGUID: String? = nil,
    limit: Int? = nil
) async throws -> [ChatItem] {
    // We turn the list of chats into just a list of chatIdentifiers
    let chatIdentifiers = chats.map(\.0)

    // Then we load the messages in those chats with the specified guid bounds
    let messages = try await ERResolveGUIDsForChats(
        withChatIdentifiers: chatIdentifiers,
        afterDate: afterDate,
        beforeDate: beforeDate,
        afterGUID: afterGUID,
        beforeGUID: beforeGUID,
        limit: limit
    )

    // Once we've got the messages, we turn them into the graph form that the other function wants
    let graph = messages.reduce(into: [String: ([String], IMServiceStyle)]()) { dict, value in
        // We get the chat that this one relates to so that we can grab its service
        if let chat = chats.first(where: { $0.id == value.chatID }) {
            // Then, if it's new to the dictionary, we just insert it
            if dict[chat.id] == nil {
                dict[chat.id] = ([value.messageID], chat.service)
            } else {
                // Else, we append it to what's already there
                // And we have to do the nasty `.0.0` thing because subscript can return a (K, V) tuple,
                // and swift is inferring that's what we wnat here, so we have to grab the value from the
                // tuple that it returns, then append to the first item in that tuple.
                dict[chat.id]?.0.append(value.messageID)
            }
        }
    }

    return try await BLLoadChatItems(withGraph: graph)
}

typealias IMFileTransferFromIMDAttachmentRecordRefType = @convention(c) (_ record: Any) -> IMFileTransfer?

private let IMDaemonCore = "/System/Library/PrivateFrameworks/IMDaemonCore.framework/IMDaemonCore"
    .withCString({
        dlopen($0, RTLD_LAZY)
    })!

private let _IMFileTransferFromIMDAttachmentRecordRef = "IMFileTransferFromIMDAttachmentRecordRef"
    .withCString({ dlsym(IMDaemonCore, $0) })
private let IMFileTransferFromIMDAttachmentRecordRef = unsafeBitCast(
    _IMFileTransferFromIMDAttachmentRecordRef,
    to: IMFileTransferFromIMDAttachmentRecordRefType.self
)

func BLLoadFileTransfer(withGUID guid: String) -> IMFileTransfer? {
    guard let attachment = IMDAttachmentRecordCopyAttachmentForGUID(guid as CFString) else {
        return nil
    }

    return IMFileTransferFromIMDAttachmentRecordRef(attachment)
}

func BLLoadAttachmentPathForTransfer(withGUID guid: String) -> String? {
    BLLoadFileTransfer(withGUID: guid)?.localPath
}
