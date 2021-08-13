//
//  ToJSONSynthesis.swift
//  BarcelonaJS
//
//  Created by Eric Rabil on 8/13/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import JavaScriptCore

func JSObjectMakeSynthesizingToJSONFunctionWithContext(_ context: JSGlobalContextRef) -> JSObjectRef {
    JSObjectMakeFunctionWithCallback(context, JSStringCreateWithCFString("toJSON" as CFString)) { ctx, fn, this, argCount, args, exception in
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
}

extension JSValue {
    convenience init(synthesizingToJSONIn context: JSContext) {
        self.init(jsValueRef: JSObjectMakeSynthesizingToJSONFunctionWithContext(context.jsGlobalContextRef), in: context)
    }
}
