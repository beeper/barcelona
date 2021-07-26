//
//  PhantomChatItem.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/4/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import os.log

public struct PhantomChatItem: ChatItem, Hashable {
    public static let ingestionClasses: [NSObject.Type] = []
    
    public init(ingesting item: NSObject, context: IngestionContext) {
        self.init(item, chatID: context.chatID)
    }
    
    init(_ item: Any?, chatID chat: String?) {
        id = NSString.stringGUID()
        fromMe = false
        time = 0
        chatID = chat
        
        if let obj = item {
            className = NSStringFromClass(Swift.type(of: obj as AnyObject))
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
    
    public var id: String
    public var chatID: String?
    public var fromMe: Bool?
    public var time: Double?
    public var threadIdentifier: String?
    public var threadOriginator: String?
    public var className: String
    
    public var type: ChatItemType {
        .phantom
    }
}
