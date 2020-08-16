//
//  IMChatRegistry+LoadMessageWithGUID.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/5/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import NIO
import IMCore
import os.log

let log_IMChat = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "IMChat+MessageQueries")

private let messageQuerySystem = MultiThreadedEventLoopGroup.init(numberOfThreads: 5)

/**
 Provides various functions to aid in the lazy resolution of messages
 */
extension IMChat {
    var chatItemRules: IMTranscriptChatItemRules {
        return self.value(forKey: "_chatItemRules") as! IMTranscriptChatItemRules
    }
    
    /**
     Loads a single message into memory and resolves it once it is complete
     */
    func loadMessage(withGUID messageGUID: String, _ callback: @escaping (IMMessage?) -> ()) {
        IMMessage.message(withGUID: messageGUID, on: messageQuerySystem.next()).whenComplete { result in
            switch result {
            case .success(let message):
                callback(message)
            case .failure(let error):
                print("Failed to load message with error \(error)")
                callback(nil)
            }
        }
    }
    
    /**
     Load a set of messages surrounding a GUID
     */
    func loadMessages(around guid: String?, numberBefore: UInt64, numberAfter: UInt64, _ callback: @escaping ([ChatItem]) -> ()) {
        var queryID: String
        
        if let guid = guid {
            queryID = self.loadMessagesBeforeAnd(afterGUID: guid, numberOfMessagesToLoadBeforeGUID: numberBefore, numberOfMessagesToLoadAfterGUID: numberAfter, loadImmediately: false)
        } else {
            queryID = self.loadMessages(beforeDate: nil, limit: numberBefore + numberAfter + 1, loadImmediately: false)
        }
        
        // Wait for query to resolve
        IMQueryWatcher.sharedInstance.waitForQuery(queryID: queryID) { _ in
            let items = self.value(forKey: "_items") as! [IMItem]
            
            let parsed = items.sorted { (item1, item2) in
                item1.time.compare(item2.time) == .orderedDescending
            }.split {
                $0.guid == guid
            }.last?.prefix(Int(numberBefore + numberAfter + 1)).compactMap {
                wrapChatItem(unknownItem: $0, withChatGroupID: self.groupID)
            } ?? []
            
            callback(parsed)
        }
    }
    
    /**
     Loads all messages before a given GUID, or from latest if omitted.
     */
    func loadMessages(before guid: String?, limit: UInt64, _ callback: @escaping ([ChatItem]) -> ()) {
        return loadMessages(around: guid, numberBefore: limit - 1, numberAfter: 0, callback)
    }
}
