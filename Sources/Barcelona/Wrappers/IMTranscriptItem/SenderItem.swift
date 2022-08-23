//
//  SenderChatItem.swift
//  imcore-rest
//
//  Created by Eric Rabil on 7/24/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

public struct SenderItem: ChatItem, Hashable {
    public static let ingestionClasses: [NSObject.Type] = [IMSenderChatItem.self]
    
    public init(ingesting item: NSObject, context: IngestionContext) {
        self.init(item as! IMSenderChatItem, chatID: context.chatID)
    }
    
    init(_ item: IMSenderChatItem, chatID chat: String) {
        id = item.id
        chatID = chat
        fromMe = item.isFromMe
        time = item.effectiveTime
        handleID = item.handle?.id
    }
    
    public var id: String
    public var chatID: String
    public var fromMe: Bool
    public var time: Double
    public var threadIdentifier: String?
    public var threadOriginator: String?
    public var handleID: String?
    
    public var type: ChatItemType {
        .sender
    }
}
