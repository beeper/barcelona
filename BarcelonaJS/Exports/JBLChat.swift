//
//  JBLChat.swift
//  BarcelonaJS
//
//  Created by Eric Rabil on 8/11/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import JavaScriptCore
import Barcelona

@objc
public protocol JBLChatJSExports: JSExport {
    var id: String { get set }
    var name: String? { get set }
    var style: UInt8 { get set }
    var participants: [String] { get set }
    var service: String { get set }
    
    static func chatWith(id: String) -> JBLChat
    static func allChats() -> [JBLChat]
    func sendText(_ text: String) -> JBLMessageExports?
    func sendTapbackToMessage(_ item: String, _ message: String, _ type: Int) -> JBLMessageExports?
    func setTyping(_ typing: Bool)
    func markAllMessagesAsRead()
}

@objc
public class JBLChat: NSObject, JBLChatJSExports {
    public dynamic var id: String
    public dynamic var name: String?
    public dynamic var style: UInt8
    public dynamic var participants: [String]
    public dynamic var service: String
    
    public init(chat: Chat) {
        id = chat.id
        name = chat.displayName
        style = (ChatStyle(rawValue: chat.style) ?? .single).rawValue
        participants = chat.participants
        service = (chat.service ?? .SMS).rawValue
    }
    
    public class func allChats() -> [JBLChat] {
        Chat.allChats.map(JBLChat.init(chat:))
    }
    
    public class func chatWith(id: String) -> JBLChat {
        JBLChat(chat: Chat.resolve(withIdentifier: id)!)
    }
    
    public func sendText(_ text: String) -> JBLMessageExports? {
        guard let message = try? chat.send(message: .init(parts: [.init(type: .text, details: text)])).first else {
            return nil
        }
        
        return JBLMessage(message: message)
    }
    
    public func sendAttachmentWithFilenameAndPath(_ filename: String, _ path: String) -> JBLMessageExports? {
        let attachment = CBInitializeFileTransfer(filename: filename, path: URL(fileURLWithPath: path))
        
        guard let message = try? chat.send(message: .init(parts: [.init(type: .attachment, details: attachment.guid)])).first else {
            return nil
        }
        
        return JBLMessage(message: message)
    }
    
    public func sendTapbackToMessage(_ item: String, _ message: String, _ type: Int) -> JBLMessageExports? {
        guard let message = try? chat.tapback(TapbackCreation(item: item, message: message, type: type)) else {
            return nil
        }
        
        return JBLMessage(message: message)
    }
    
    public func setTyping(_ typing: Bool) {
        chat.setTyping(typing)
    }
    
    public func markAllMessagesAsRead() {
        chat.imChat.markAllMessagesAsRead()
    }
    
    public var chat: Chat! {
        Chat.resolve(withIdentifier: id)
    }
    
    public func messages() -> JSPromise {
        let jPromise = JSPromise()
        
        return jPromise
    }
}
