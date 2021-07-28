//
//  FulfillMessageObjects.swift
//  Barcelona
//
//  Created by Eric Rabil on 7/25/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import BarcelonaFoundation
import IMCore

// MARK: - IMFileTransfer Preload
private func BLLoadFileTransfers(forObjects objects: [NSObject]) -> Promise<Void, Error> {
    let unloadedFileTransferGUIDs = objects.compactMap {
        $0 as? IMFileTransferContainer
    }.flatMap(\.unloadedFileTransferGUIDs)
    
    guard unloadedFileTransferGUIDs.count > 0 else {
        return .success(())
    }
    
    return DBReader.shared.attachments(withGUIDs: unloadedFileTransferGUIDs).then {
        $0.forEach {
            $0.registerFileTransferIfNeeded()
        }
    }
}

// MARK: - Associated Resolution
private func BLLoadTapbacks(forItems items: [ChatItem], inChat chat: String) -> Promise<[ChatItem], Error> {
    let messages = items.compactMap { $0 as? Message }.dictionary(keyedBy: \.id)
    
    let associatedLedger = messages.values.flatMap { message in
        message.associableItemIDs.map {
            (itemID: $0, messageID: message.id)
        }
    }.dictionary(keyedBy: \.itemID, valuedBy: \.messageID)
    
    guard associatedLedger.count > 0 else {
        return .success(items)
    }
    
    return DBReader.shared.associatedMessages(with: messages.values.flatMap(\.associableItemIDs), in: chat).then { associations in
        associations.forEach { itemID, associatedMessages in
            guard let messageID = associatedLedger[itemID], let message = messages[messageID] else {
                return
            }
            
            guard let item = message.items.first(where: { $0.id == itemID }), item.isAcknowledgable else {
                return
            }
            
            item.acknowledgments = associatedMessages.flatMap(\.items).compactMap { item in
                item.item as? AcknowledgmentChatItem
            }
        }
    }.then {
        Array(messages.values) + items.filter { $0.type != .message }
    }
}

// MARK: - Translation
private func BLParseObjects(_ objects: [NSObject], inChat chat: String) -> [ChatItem] {
    objects.map {
        ChatItemType.ingest(object: $0, context: IngestionContext(chatID: chat))
    }
}

// MARK: - Chat ID resolution
private func BLResolveChatID(forObject object: NSObject) -> Promise<String, Error> {
    if let object = object as? IMItemIDResolvable, let guid = object.itemGUID {
        return DBReader.shared.chatIdentifier(forMessageGUID: guid)
            .assert(BarcelonaError(code: 500, message: "Failed to resolve item IDs during ingestion"))
    } else {
        return .failure(BarcelonaError(code: 500, message: "Failed to resolve item IDs during ingestion"))
    }
}

private func BLResolveChatIDs(forObjects objects: [NSObject]) -> Promise<[String], Error> {
    let ids = objects.compactMap {
        ($0 as? IMItemIDResolvable)?.itemGUID
    }
    
    guard ids.count == objects.count else {
        return .failure(BarcelonaError(code: 500, message: "Failed to resolve item IDs during ingestion"))
    }
    
    return DBReader.shared.chatIdentifiers(forMessageGUIDs: ids)
}

private protocol IMItemIDResolvable {
    var itemGUID: String? { get }
}

extension IMItem: IMItemIDResolvable {
    var itemGUID: String? { guid }
}

extension IMChatItem: IMItemIDResolvable {
    var itemGUID: String? { _item()?.guid }
}

extension IMMessage: IMItemIDResolvable {
    var itemGUID: String? { guid }
}

// MARK: - Public API
public func BLIngestObjects(_ objects: [NSObject], inChat chat: String? = nil) -> Promise<[ChatItem], Error> {
    guard let chat = chat else {
        return BLResolveChatIDs(forObjects: objects)
            .then { chatIDs -> Promise<[ChatItem], Error> in
                if _fastPath(chatIDs.allSatisfy { $0 == chatIDs.first }) {
                    return BLIngestObjects(objects, inChat: chatIDs.first!)
                }
                
                // Loads file transfers in one batch to reduce database calls
                return BLLoadFileTransfers(forObjects: objects).then {
                    Promise.whenAllSucceed(objects.enumerated().map { index, object in
                        BLIngestObject(object, inChat: chatIDs[index])
                    })
                }
            }
    }
    
    return BLLoadFileTransfers(forObjects: objects).then {
        BLParseObjects(objects, inChat: chat)
    }.then {
        BLLoadTapbacks(forItems: $0, inChat: chat)
    }.receive(on: DispatchQueue.main)
}

public func BLIngestObject(_ object: NSObject, inChat chat: String? = nil) -> Promise<ChatItem, Error> {
    guard let chat = chat else {
        return BLResolveChatID(forObject: object)
            .then { chat in
                BLIngestObject(object, inChat: chat)
            }
    }
    
    return BLIngestObjects([object], inChat: chat).then {
        $0.first!
    }
}
