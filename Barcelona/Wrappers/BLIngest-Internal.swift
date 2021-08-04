//
//  BLIngest-Internal.swift
//  Barcelona
//
//  Created by Eric Rabil on 8/3/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import BarcelonaDB

@usableFromInline
internal let BLIngestLog = Logger(category: "BLIngest-Internal")

@usableFromInline
internal protocol IMItemIDResolvable {
    var itemGUID: String? { get }
}

extension IMItem: IMItemIDResolvable {
    @usableFromInline
    var itemGUID: String? { guid }
}

extension IMChatItem: IMItemIDResolvable {
    @usableFromInline
    var itemGUID: String? { _item()?.guid }
}

extension IMMessage: IMItemIDResolvable {
    @usableFromInline
    var itemGUID: String? { guid }
}

// MARK: - IMFileTransfer Preload
@inlinable
internal func _BLLoadFileTransfers(forObjects objects: [NSObject]) -> Promise<Void> {
    let operation = BLIngestLog.operation(named: "BLLoadFileTransfers").begin("loading file transfers for %d objects", objects.count)
    
    let unloadedFileTransferGUIDs = objects.compactMap {
        $0 as? IMFileTransferContainer
    }.flatMap(\.unloadedFileTransferGUIDs)
    
    guard unloadedFileTransferGUIDs.count > 0 else {
        operation.end("aborting file transfer loading because there are no unloaded file transfers")
        return .success(())
    }
    
    operation.event("loading %d transfers", unloadedFileTransferGUIDs.count)
    
    return DBReader.shared.attachments(withGUIDs: unloadedFileTransferGUIDs).endingOperation(operation) { attachments in
        operation.end("loaded %d attachments", attachments.count)
    }.compactMap(\.internalAttachment).forEach {
        $0.registerFileTransferIfNeeded()
    }
}

@inlinable
internal func _BLLoadAcknowledgmentChatItems(withMessageGUIDs messageGUIDs: [String], inChat chat: String) -> [String: [AcknowledgmentChatItem]] {
    _BLParseObjects(BLLoadIMMessages(withGUIDs: messageGUIDs), inChat: chat).compactMap {
        $0 as? Message
    }.flatMap(\.items).map(\.item).compactMap {
        $0 as? AcknowledgmentChatItem
    }.collectedDictionary(keyedBy: \.associatedID)
}

// MARK: - Associated Resolution
@inlinable
internal func _BLLoadTapbacks(forItems items: [ChatItem], inChat chat: String) -> Promise<[ChatItem]> {
    var operation = BLIngestLog.operation(named: "BLLoadTapbacks (db)").begin("querying tapbacks for %d items in chat %@", items.count, chat)
    
    let messages = items.compactMap { $0 as? Message }.dictionary(keyedBy: \.id)
    
    let associatedLedger = messages.values.flatMap { message in
        message.associableItemIDs.map {
            (itemID: $0, messageID: message.id)
        }
    }.dictionary(keyedBy: \.itemID, valuedBy: \.messageID)
    
    guard associatedLedger.count > 0 else {
        operation.end("early-exit because there's no associable items")
        return .success(items)
    }
    
    return DBReader.shared.associatedMessageGUIDs(with: messages.values.flatMap(\.associableItemIDs)).then { associations -> [String: [AcknowledgmentChatItem]] in
        operation.end("loaded %d associated items from db", associations.flatMap(\.value).count)
        
        operation = BLIngestLog.operation(named: "BLLoadTapbacks (IMDPersistence)").begin("loading items from IMDPersistenceAgent")
        
        return _BLLoadAcknowledgmentChatItems(withMessageGUIDs: associations.flatMap(\.value), inChat: chat)
    }.observeAlways { completion in
        switch completion {
        case .failure(let error):
            operation.end("failed to load with error %@", error as NSError)
        case .success(let items):
            operation.end("loaded %d items", items.flatMap(\.value).count)
        }
    }.then { ledger -> [ChatItem] in
        operation = BLIngestLog.operation(named: "BLLoadTapbacks (organize)").begin()
        
        ledger.forEach { itemID, tapbacks -> Void in
            guard let messageID = associatedLedger[itemID], let message = messages[messageID] else {
                return
            }
            
            guard let item = message.items.first(where: { $0.id == itemID }), item.isAcknowledgable else {
                return
            }
            
            item.acknowledgments = tapbacks
        }
        
        defer {
            operation.end()
        }
        
        return Array(messages.values) + items.filter { $0.type != .message }
    }
}

// MARK: - Translation
@inlinable
internal func _BLParseObjects(_ objects: [NSObject], inChat chat: String) -> [ChatItem] {
    let operation = BLIngestLog.operation(named: "BLParseObjects").begin("parsing %d objects in chat %@", objects.count, chat)
    
    defer { operation.end() }
    
    return objects.map {
        ChatItemType.ingest(object: $0, context: IngestionContext(chatID: chat))
    }
}

// MARK: - Chat ID resolution
@inlinable
internal func _BLResolveChatID(forObject object: NSObject) -> Promise<String> {
    if let object = object as? IMItemIDResolvable, let guid = object.itemGUID {
        return DBReader.shared.chatIdentifier(forMessageGUID: guid)
            .assert(BarcelonaError(code: 500, message: "Failed to resolve item IDs during ingestion"))
    } else {
        return .failure(BarcelonaError(code: 500, message: "Failed to resolve item IDs during ingestion"))
    }
}

@inlinable
internal func _BLResolveChatIDs(forObjects objects: [NSObject]) -> Promise<[String]> {
    guard objects.count > 0 else {
        return .success([])
    }
    
    let ids = objects.compactMap {
        ($0 as? IMItemIDResolvable)?.itemGUID
    }
    
    guard ids.count == objects.count else {
        return .failure(BarcelonaError(code: 500, message: "Failed to resolve item IDs during ingestion"))
    }
    
    return DBReader.shared.chatIdentifiers(forMessageGUIDs: ids)
}
