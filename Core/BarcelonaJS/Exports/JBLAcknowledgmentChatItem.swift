//
//  JBLAcknowledgmentChatItem.swift
//  BarcelonaJS
//
//  Created by Eric Rabil on 8/11/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import JavaScriptCore
import Barcelona

@objc
public protocol JBLAcknowledgmentChatItemExports: JBLChatItemExports, JSExport {
    var acknowledgmentType: Int { get set }
    var associatedID: String { get set }
}

@objc
public class JBLAcknowledgmentChatItem: JBLChatItem, JBLAcknowledgmentChatItemExports {
    public dynamic var acknowledgmentType: Int
    public dynamic var associatedID: String
    
    public init(item: AcknowledgmentChatItem) {
        acknowledgmentType = Int(item.acknowledgmentType)
        associatedID = item.associatedID
        super.init(item: item)
    }
}
