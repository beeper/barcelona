//
//  JSContext+Atomic.swift
//  BarcelonaJS
//
//  Created by Eric Rabil on 8/13/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import JavaScriptCore

private extension JSContext {
    var queue: DispatchQueue {
        get {
            guard let queue = objc_getAssociatedObject(self, "_atomic_queue") as? DispatchQueue else {
                self.queue = DispatchQueue(label: "com.barcelona.atomic-js")
                return self.queue
            }
            
            return queue
        }
        set {
            objc_setAssociatedObject(self, "_atomic_queue", newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
}

public extension JSContext {
    func evaluateScript(atomically code: String) -> JSValue {
        queue.sync {
            evaluateScript(code)
        }
    }
}
