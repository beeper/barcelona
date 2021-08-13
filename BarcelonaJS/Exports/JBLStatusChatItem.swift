//
//  JBLStatusChatItem.swift
//  BarcelonaJS
//
//  Created by Eric Rabil on 8/11/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import JavaScriptCore
import Barcelona

@objc
public protocol JBLStatusChatItemJSExports: JBLChatItemExports, JSExport {
    var statusType: StatusType.RawValue { get set }
}

@objc
public class JBLStatusChatItem: JBLChatItem, JBLStatusChatItemJSExports {
    public var statusType: StatusType.RawValue
    
    public init(item: StatusChatItem) {
        statusType = item.statusType?.rawValue ?? 0
        super.init(item: item)
    }
}
