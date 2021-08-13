//
//  BarcelonaJSFoundation.swift
//  BarcelonaJSFoundation
//
//  Created by Eric Rabil on 8/13/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
@_exported import JavaScriptCore
import Swog

@_cdecl("JSContextCreateBaseContext")
public func JSContextCreateBaseContext() -> JSContext {
    let context = JSContext()!
    
    context["console"] = JSConsole.self
    context["Promise"] = JSPromise.self
    
    context.exceptionHandler = { context, exception in
        CLFault("BarcelonaJS", "Unhandled exception: %@", exception?.inspectionString ?? "(nil)")
    }
    
    return context
}

public func JSContextCreateBaseContextWithAPIs(_ apis: [Any]) -> JSContext {
    let context = JSContextCreateBaseContext()
    
    context.addAPIs(apis)
    
    return context
}

public func JSContextCreateBaseContextWithAPIs(_ creationBlock: @convention(c) (JSContext) -> [Any]) -> JSContext {
    let context = JSContextCreateBaseContext()
    
    context.addAPIs(creationBlock(context))
    
    return context
}
