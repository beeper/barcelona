//
//  JSConsole.swift
//  BarcelonaJS
//
//  Created by Eric Rabil on 8/13/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import JavaScriptCore

@objc
public protocol JSConsoleExports: JSExport {
    static func log(_ msg: String)
}

public class JSConsole: NSObject, JSConsoleExports {
    public class func log(_ msg: String) {
        print(msg)
    }
}
