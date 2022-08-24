//
//  JBLTextChatItem.swift
//  BarcelonaJS
//
//  Created by Eric Rabil on 8/11/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import Barcelona
import JavaScriptCore

@objc
public protocol JBLTextChatItemExports: JBLChatItemExports, JSExport {
    @objc var text: String { get set }
}

@objc
public class JBLTextChatItem: JBLChatItem, JBLTextChatItemExports {
    public dynamic var text: String
    
    public init(item: TextChatItem) {
        text = item.text
        super.init(item: item)
    }
}
