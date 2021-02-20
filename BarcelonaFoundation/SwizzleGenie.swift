//
//  SwizzleGenie.swift
//  BarcelonaFoundation
//
//  Created by Eric Rabil on 9/26/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation

@objc private class BadBitchSwizzleQueen: NSObject {
    @objc func badBitchSwizzle(_ dummyThixx: Any, withAssHole: Any) {
        
    }
}

public struct SwizzleGenie {
    public init(swizzlee: AnyClass, swizzler: AnyClass) {
        self.swizzlee = swizzlee
        self.swizzler = swizzler
    }
    
    var swizzlee: AnyClass
    var swizzler: AnyClass
    
    public func swizzle(originalMethod: String, targetMethod: String) {
        let originalSelector = Selector(originalMethod)
        let newSelector = Selector(targetMethod)
        
        let originalMethod = class_getInstanceMethod(swizzlee.self, originalSelector)!
        let newMethod = class_getInstanceMethod(swizzler.self, newSelector)!
        
        method_exchangeImplementations(originalMethod, newMethod)
    }
}
