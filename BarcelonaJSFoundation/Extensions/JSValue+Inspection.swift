//
//  JSValue+Inspection.swift
//  BarcelonaJS
//
//  Created by Eric Rabil on 8/13/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import JavaScriptCore

public extension JSValue {
    func stringify() -> JSStringRef? {
        JSValueCreateJSONString(context.jsGlobalContextRef, jsValueRef, 4, nil)
    }
    
    var inspectionString: String? {
        if isFunction {
            return description
        } else {
            return JSStringCopyCFString(kCFAllocatorDefault, stringify()) as String?
        }
    }
}
