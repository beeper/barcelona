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
    
    static func chatWith(id: String) -> JBLChat?
    static func allChats() -> [JBLChat]
    func sendText(_ text: String) -> JBLMessageExports?
    func sendTapbackToMessage(_ item: String, _ message: String, _ type: Int) -> JBLMessageExports?
    func setTyping(_ typing: Bool)
    func markAllMessagesAsRead()
    func messages(_ parameters: JSValue?) -> JSPromise
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
    
    public class func chatWith(id: String) -> JBLChat? {
        guard let chat = Chat.resolve(withIdentifier: id) else {
            return nil
        }
        
        return JBLChat(chat: chat)
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
    
    public func messages(_ parameters: JSValue? = nil) -> JSPromise {
        let jPromise = JSPromise()
        
        let dictionary = parameters.dictionaryView
        
        chat.messages(before: dictionary["before"], limit: dictionary["limit"], beforeDate: dictionary["beforeDate"])
            .map(JBLMessage.init(message:))
            .then {
                jPromise.success(value: $0)
            }
            .catch {
                jPromise.fail(error: $0.localizedDescription)
            }
        
        return jPromise
    }
}

class JSDictionaryView {
    let source: JSValue?
    
    init(_ source: JSValue?) {
        switch source {
        case .some(let value):
            if !value.isObject || (value.isNull() || value.isUndefined) {
                self.source = nil
                break
            }
            
            self.source = value
        case .none:
            self.source = nil
        }
    }
    
    subscript (_ key: String) -> String? {
        get {
            guard let value = source?[key], value.isString else {
                return nil
            }
            
            return value.toString()
        }
    }
    
    subscript (_ key: String) -> Int? {
        get {
            guard let value = source?[key], value.isNumber else {
                return nil
            }
            
            return value.toNumber().intValue
        }
    }
    
    subscript (_ key: String) -> Date? {
        get {
            guard let value = source?[key] else {
                return nil
            }
            
            if value.isDate {
                return value.toDate()
            } else if value.isNumber {
                return Date(timeIntervalSince1970: value.toNumber().doubleValue / 1000)
            } else {
                return nil
            }
        }
    }
}

internal extension JSValue {
    var dictionaryView: JSDictionaryView {
        JSDictionaryView(self)
    }
}

internal extension Optional where Wrapped == JSValue {
    var dictionaryView: JSDictionaryView {
        switch self {
        case .some(let value):
            return value.dictionaryView
        case .none:
            return JSDictionaryView(nil)
        }
    }
}

internal func JBLCreateJSONString(_ value: JSValue) -> String {
    JSStringCopyCFString(kCFAllocatorDefault, JSValueCreateJSONString(value.context.jsGlobalContextRef, value.jsValueRef, 0, nil)) as String
}

internal func JBLCreateJSON(_ value: JSValue) -> Data {
    Data(JBLCreateJSONString(value).utf8)
}

internal func JBLDecodeJSON<P: Decodable>(_ json: JSValue) throws -> P {
    try JSONDecoder().decode(P.self, from: JBLCreateJSON(json))
}

@_transparent
internal func JBLDecodeJSON<P: Decodable>(_ json: JSValue, as: P.Type) throws -> P{
    try JBLDecodeJSON(json)
}
