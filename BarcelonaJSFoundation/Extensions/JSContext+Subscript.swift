//
//  JSContext+Subscript.swift
//  BarcelonaJS
//
//  Created by Eric Rabil on 8/13/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import JavaScriptCore

private extension JSContext {
    var toJSON: JSValue {
        guard let toJSON = objc_getAssociatedObject(self, "_toJSON") as? JSValue else {
            objc_setAssociatedObject(self, "_toJSON", JSValue(synthesizingToJSONIn: self), .OBJC_ASSOCIATION_RETAIN)
            return self.toJSON
        }
        
        return toJSON
    }
}

public extension JSContext {
    subscript(key: String) -> Any {
        get {
            return self.objectForKeyedSubscript(key)
        }
        set{
            self.setObject(newValue, forKeyedSubscript: key as NSCopying & NSObjectProtocol)
            
            if newValue is AnyClass {
                // makes properties enumerable because the javascriptcore developers are shits
                let prototype = evaluateScript(atomically: "\(key).prototype")
                
                for property in prototype.propertyNames.filter({ $0 != "constructor" }) {
                    let descriptor = prototype[descriptor: property]
                    
                    guard !descriptor.isNull else {
                        continue
                    }
                    
                    guard let enumerable = descriptor[JSPropertyDescriptorEnumerableKey], enumerable.toBool() == false else {
                        continue
                    }
                    
                    descriptor.setObject(true, forKeyedSubscript: JSPropertyDescriptorEnumerableKey)
                    
                    prototype[descriptor: property] = descriptor
                }
                
                prototype["toJSON"] = toJSON
            }
        }
    }
}

public extension JSContext {
    func addAPIs(_ apis: [Any]) {
        for api in apis {
            let name = api is AnyClass ? String(describing: api) : String(describing: type(of: api))
            self[name] = api
        }
    }
}
