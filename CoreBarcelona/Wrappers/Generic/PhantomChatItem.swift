//
//  PhantomChatItem.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/4/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import os.log

struct PhantomChatItem: ChatItemRepresentation {
    init(_ item: Any?, chatID chat: String?) {
        id = NSString.stringGUID()
        fromMe = false
        time = 0
        chatID = chat
        
        if let obj = item {
            className = NSStringFromClass(type(of: obj as AnyObject))
        } else {
            className = String(describing: item)
        }
        
        switch item {
        case let item as IMTranscriptChatItem:
            load(item: item, chatID: chat)
        case let item as IMItem:
            load(item: item, chatID: chat)
        default:
            break
        }
        
        os_log("PhantomChatItem created with unknown item: %@", log: .default, type: .error, className)
    }
    
    var id: String?
    var chatID: String?
    var fromMe: Bool?
    var time: Double?
    var className: String
}
