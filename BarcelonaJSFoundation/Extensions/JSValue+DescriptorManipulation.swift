//
//  JSObject+DescriptorManipulation.swift
//  BarcelonaJS
//
//  Created by Eric Rabil on 8/13/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import JavaScriptCore

extension JSValue {
    subscript(descriptor name: String) -> JSValue {
        get {
            context.evaluateScript("(proto, prop) => Object.getOwnPropertyDescriptor(proto, prop)")!.call(withArguments: [self, JSValue(object: name, in: context)!])
        }
        set {
            context.evaluateScript("(proto, prop, desc) => Object.defineProperty(proto, prop, desc)")!.call(withArguments: [self, JSValue(object: name, in: context)!, newValue])
        }
    }
}
