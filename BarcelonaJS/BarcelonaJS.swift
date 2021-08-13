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
            let result = context.evaluateScript(code)!
            
            if result.isFunction {
                return result.description
            } else {
                return JSStringCopyCFString(kCFAllocatorDefault, JSValueCreateJSONString(context.jsGlobalContextRef, context.evaluateScript(code).jsValueRef, 4, nil)) as String
            }
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
    
    let getDescriptor = context.evaluateScript("(proto, prop) => Object.getOwnPropertyDescriptor(proto, prop)")!
    let setDescriptor = context.evaluateScript("(proto, prop, desc) => Object.defineProperty(proto, prop, desc)")!
    
    let toJSONRef = JSObjectMakeFunctionWithCallback(context.jsGlobalContextRef, JSStringCreateWithCFString("toJSON" as CFString)) { ctx, fn, this, argCount, args, exception in
        let context = JSContext(jsGlobalContextRef: ctx)!
        let this = JSValue(jsValueRef: this, in: context)!

        if let prototype = this["constructor"]?["prototype"] {
            let object = JSValue(newObjectIn: context)!
            
            let names = JSObjectCopyPropertyNames(ctx, prototype.jsValueRef)
            
            for i in 0..<JSPropertyNameArrayGetCount(names) {
                let name = JSStringCopyCFString(kCFAllocatorDefault, JSPropertyNameArrayGetNameAtIndex(names, i)!) as String
                object[name] = this[name]
            }
            
            return object.jsValueRef
        }
        
        return JSObjectMake(ctx, nil, nil)
    }
    
    let toJSON = JSValue(jsValueRef: toJSONRef, in: context)
    
    for api in JBLExposedAPIs {
        let name = api is AnyClass ? String(describing: api) : String(describing: type(of: api))
        context.setObject(api, forKeyedSubscript: name as NSString)
        
        if api is AnyClass {
            let prototype = context.evaluateScript("\(name).prototype")!
            
            for property in prototype.propertyNames.filter({ $0 != "constructor" }).map({ JSValue(object: $0, in: context)! }) {
                guard let descriptor = getDescriptor.call(withArguments: [prototype, property]) else {
                    continue
                }
                
                guard let enumerable = descriptor[JSPropertyDescriptorEnumerableKey], enumerable.toBool() == false else {
                    continue
                }
                
                descriptor.setObject(true, forKeyedSubscript: JSPropertyDescriptorEnumerableKey)
                
                setDescriptor.call(withArguments: [prototype, property, descriptor])
            }
            
            prototype["toJSON"] = toJSON
        }
    }
    
    return context
}
