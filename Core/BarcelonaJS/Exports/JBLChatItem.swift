//
//  JBLChatItem.swift
//  BarcelonaJS
//
//  Created by Eric Rabil on 8/11/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import JavaScriptCore
import Barcelona
import IMCore

@objc
public protocol JBLChatItemExports: JSExport {
    var id: String { get set }
    var type: String { get set }
    var acknowledgments: [JBLAcknowledgmentChatItemExports]? { get set }
}

@objc
public class JBLChatItem: NSObject, JBLChatItemExports {
    public dynamic var id: String
    public dynamic var type: String
    public dynamic var acknowledgments: [JBLAcknowledgmentChatItemExports]?
    
    public init(item: ChatItem) {
        id = item.id
        type = item.type.rawValue
        
        if let item = item as? ChatItemAcknowledgable {
            acknowledgments = item.acknowledgments?.map(JBLAcknowledgmentChatItem.init(item:))
        }
    }
}
