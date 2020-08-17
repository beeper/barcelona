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
    internal mutating func load(item: IMItem, chatGroupID chat: String?) {
        guid = item.guid
        chatGroupID = chat
        fromMe = item.isFromMe
        time = (item.time?.timeIntervalSince1970 ?? 0) * 1000
    }
    
    internal mutating func load(item: IMTranscriptChatItem, chatGroupID chat: String?) {
        
        guid = item.guid
        chatGroupID = chat
        fromMe = item.isFromMe
        time = ((item.transcriptDate ?? item._timeAdded())?.timeIntervalSince1970 ?? item._item()?.time?.timeIntervalSince1970 ?? 0) * 1000
    }
}
