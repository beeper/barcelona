//
//  ChatItem+SharedInit.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 8/17/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

extension ChatItemRepresentation {
    internal mutating func load(item: IMItem, chatID chat: String?) {
        id = item.guid as! Self.IDValue
        chatID = chat
        fromMe = item.isFromMe
        time = (item.time?.timeIntervalSince1970 ?? 0) * 1000
        
        if let item = item as? IMMessagePartChatItem, #available(iOS 14, macOS 10.16, watchOS 7, *) {
            threadIdentifier = item.threadIdentifier()
            threadOriginator = item.threadOriginator()?.guid
        }
    }
    
    internal mutating func load(item: IMTranscriptChatItem, chatID chat: String?) {
        id = item.guid as! Self.IDValue
        chatID = chat
        fromMe = item.isFromMe
        time = ((item.transcriptDate ?? item._timeAdded())?.timeIntervalSince1970 ?? item._item()?.time?.timeIntervalSince1970 ?? 0) * 1000
        
        if let item = item as? IMMessagePartChatItem, #available(iOS 14, macOS 10.16, watchOS 7, *) {
            threadIdentifier = item.threadIdentifier()
            threadOriginator = item.threadOriginator()?.guid
        }
    }
}
