//
//  JBLMessage.swift
//  BarcelonaJS
//
//  Created by Eric Rabil on 8/11/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import Barcelona
import JavaScriptCore

@objc
public protocol JBLMessageExports: JSExport {
    var id: String { get set }
    var summary: String { get set }
    var fromMe: Bool { get set }
    var chatID: String { get set }
    var time: Double { get set }
    var items: [JBLChatItemExports] { get set }
    var isTyping: Bool { get set }
    var isCancelTyping: Bool { get set }
    var timeRead: Double { get set }
    var fileTransferIDs: [String] { get set }
}

@objc
public class JBLMessage: NSObject, JBLMessageExports {
    public dynamic var id: String
    public dynamic var summary: String
    public dynamic var fromMe: Bool
    public dynamic var chatID: String
    public dynamic var time: Double
    public dynamic var items: [JBLChatItemExports]
    public dynamic var isTyping: Bool
    public dynamic var isCancelTyping: Bool
    public dynamic var timeRead: Double
    public dynamic var fileTransferIDs: [String]
    
    public init(message: Message) {
        id = message.id
        summary = message.description ?? ""
        fromMe = message.fromMe
        chatID = message.chatID
        time = message.time
        items = message.items.map { item in
            switch item.item {
            case let item as TextChatItem:
                return JBLTextChatItem(item: item)
            case let item as AttachmentChatItem:
                return JBLAttachmentChatItem(item: item)
            case let item as AcknowledgmentChatItem:
                return JBLAcknowledgmentChatItem(item: item)
            case let item as StatusChatItem:
                return JBLStatusChatItem(item: item)
            default:
                return JBLChatItem(item: item)
            }
        }
        isTyping = message.isTypingMessage
        isCancelTyping = message.isCancelTypingMessage
        timeRead = message.timeRead
        fileTransferIDs = message.fileTransferIDs
    }
}
