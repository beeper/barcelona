//
//  BarcelonaJS.swift
//  BarcelonaJS
//
//  Created by Eric Rabil on 8/11/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import JavaScriptCore

extension JSContext {
    subscript(key: String) -> Any {
        get {
            return self.objectForKeyedSubscript(key)
        }
        set{
            self.setObject(newValue, forKeyedSubscript: key as NSCopying & NSObjectProtocol)
        }
    }
}

@objc protocol JSConsoleExports: JSExport {
    static func log(_ msg: String)
}

class JSConsole: NSObject, JSConsoleExports {
    class func log(_ msg: String) {
        print(msg)
    }
}

public class JSThread {
    private let queue = DispatchQueue(label: "com.grapple.js-scope")
    
    public private(set) var context: JSContext!
    
    public init() {
        queue.sync {
            context = JBLCreateJSContext()
            context.exceptionHandler = { context, exception in
                print(exception!.toString()!)
            }
        }
    }
    
    public func execute(_ code: String) -> String {
        queue.sync {
            context.evaluateScript(code).description
        }
    }
}

@_cdecl("JBLCreateJSContext")
public func JBLCreateJSContext() -> JSContext {
    let context = JSContext()!
    
    context["console"] = JSConsole.self
    context["JSPromise"] = JSPromise.self
    
    let JBLExposedAPIs: [Any] = [
        JBLChat.self,
        JBLMessage.self,
        JBLChatItem.self,
        JBLAttachmentChatItem.self,
        JBLTextChatItem.self,
        JBLStatusChatItem.self,
        JBLAcknowledgmentChatItem.self,
        JBLAttachment.self,
        JBLEventBus(context: context),
        JBLAccount.self,
        JBLContact.self
    ]
    
    for api in JBLExposedAPIs {
        let name = api is AnyClass ? String(describing: api) : String(describing: type(of: api))
        context.setObject(api, forKeyedSubscript: name as NSString)
    }
    
    return context
}
