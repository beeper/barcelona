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
import IMSharedUtilities
import Logging

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
@MainActor
internal func _BLLoadFileTransfers(forObjects objects: [NSObject]) -> Promise<Void> {
    let log = Logger(label: "_BLLoadFileTransfers")
    let unloadedFileTransferGUIDs = objects.compactMap {
        $0 as? IMFileTransferContainer
    }.flatMap(\.unloadedFileTransferGUIDs)
    
    guard unloadedFileTransferGUIDs.count > 0 else {
        return .success(())
    }
    
    log.info("loading \(unloadedFileTransferGUIDs.count) transfers")
    
    return DBReader.shared.attachments(withGUIDs: unloadedFileTransferGUIDs).compactMap(\.attachment).forEach {
        $0.initializeFileTransferIfNeeded()
    }
}

@inlinable
internal func _BLLoadAcknowledgmentChatItems(
    withMessageGUIDs messageGUIDs: [String],
    inChat chat: String,
    service: IMServiceStyle
) -> [String: [AcknowledgmentChatItem]] {
    _BLParseObjects(BLLoadIMMessages(withGUIDs: messageGUIDs), inChat: chat, service: service).compactMap {
        $0 as? Message
    }.flatMap(\.items).map(\.item).compactMap {
        $0 as? AcknowledgmentChatItem
    }.collectedDictionary(keyedBy: \.associatedID)
}

// MARK: - Associated Resolution
@inlinable
internal func _BLLoadTapbacks(forItems items: [ChatItem], inChat chat: String, service: IMServiceStyle) -> Promise<[ChatItem]> {
    let log = Logger(label: "_BLLoadTapbacks")
    guard items.count > 0 else {
        return .success([])
    }
    
    let messages = items.compactMap { $0 as? Message }.dictionary(keyedBy: \.id)
    
    let associatedLedger = messages.values.flatMap { message in
        message.associableItemIDs.map {
            (itemID: $0, messageID: message.id)
        }
    }.dictionary(keyedBy: \.itemID, valuedBy: \.messageID)
    
    guard associatedLedger.count > 0 else {
        return .success(items)
    }
    
    return DBReader.shared.associatedMessageGUIDs(with: messages.values.flatMap(\.associableItemIDs)).then { associations -> [String: [AcknowledgmentChatItem]] in
        if associations.count == 0 {
            return [:]
        }
                
        return _BLLoadAcknowledgmentChatItems(withMessageGUIDs: associations.flatMap(\.value), inChat: chat, service: service)
    }.observeAlways { completion in
        switch completion {
        case .failure(let error):
            log.error("failed to load with error \(error as NSError)")
        default: break
        }
    }.then { ledger -> [ChatItem] in
        if ledger.values.flatten().count > 0 {
            ledger.forEach { itemID, tapbacks -> Void in
                guard let messageID = associatedLedger[itemID], let message = messages[messageID] else {
                    return
                }
                
                guard let item = message.items.first(where: { $0.id == itemID }), item.isAcknowledgable else {
                    return
                }
                
                item.acknowledgments = tapbacks
            }
            
            return Array(messages.values) + items.filter { $0.type != .message }
        } else {
            return items
        }
    }
}

// MARK: - Translation
@inlinable
internal func _BLParseObjects(_ objects: [NSObject], inChat chatId: String, service: IMServiceStyle) -> [ChatItem] {
    objects.map {
        ChatItemType.ingest(object: $0, context: IngestionContext(chatID: chatId, service: service))
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
