//
//  JSPromise.swift
//  BarcelonaJS
//
//  Created by Eric Rabil on 8/12/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import JavaScriptCore

@objc protocol JSPromiseExports: JSExport {
    func then(_ resolve: JSValue) -> JSPromise
    func `catch`(_ reject: JSValue) -> JSPromise
}

public class JSPromise: NSObject, JSPromiseExports {
    var resolve: JSValue?
    var reject: JSValue?
    var next: JSPromise?
    
    func then(_ resolve: JSValue) -> JSPromise {
        self.resolve = resolve
        
        self.next = JSPromise()
        
        return self.next!
    }
    
    func `catch`(_ reject: JSValue) -> JSPromise {
        self.reject = reject
        self.next = JSPromise()
        
        return self.next!
    }
    
    func fail(error: String) {
        if let reject = reject {
            reject.call(withArguments: [error])
        } else if let next = next {
            next.fail(error: error)
        }
    }
    
    public func success(value: Any?) {
        guard let resolve = resolve else { return }
        var result:JSValue?
        if let value = value  {
            result = resolve.call(withArguments: [value])
        } else {
            result = resolve.call(withArguments: [])
        }

        guard let next = next else { return }
        if let result = result {
            if result.isUndefined {
                next.success(value: nil)
                return
            } else if (result.hasProperty("isError")) {
                next.fail(error: result.toString())
                return
            }
        }
        
        next.success(value: result)
    }
}
