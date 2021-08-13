//
//  JSValue+SaneBridging.swift
//  BarcelonaJS
//
//  Created by Eric Rabil on 8/13/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import JavaScriptCore

public extension JSValue {
    var isFunction: Bool {
        guard isObject else {
            return false
        }
        
        return JSObjectIsFunction(context.jsGlobalContextRef, jsValueRef)
    }
    
    var getOwnPropertyNames: JSValue {
        context.evaluateScript("Object.getOwnPropertyNames")!
    }
    
    var propertyNames: [String] {
        guard !isNull else {
            return []
        }
        
        return getOwnPropertyNames.call(withArguments: [self]).toArray()?.compactMap { $0 as? String } ?? []
    }
    
    var prototype: JSValue? {
        guard !isNull, let ref = JSObjectGetPrototype(context.jsGlobalContextRef, jsValueRef) else {
            return nil
        }
        
        return JSValue(jsValueRef: ref, in: context)
    }
    
    subscript(key: String) -> JSValue? {
        get {
            guard isObject, !isNull else {
                return nil
            }
            
            return JSValue(jsValueRef: JSObjectGetProperty(context.jsGlobalContextRef, jsValueRef, JSStringCreateWithCFString(key as CFString), nil), in: context)
        }
        set {
            JSObjectSetProperty(context.jsGlobalContextRef, jsValueRef, JSStringCreateWithCFString(key as CFString), newValue?.jsValueRef ?? JSValueMakeNull(context.jsGlobalContextRef), JSPropertyAttributes(kJSPropertyAttributeNone), nil)
        }
    }
}
