//
//  PhantomChatItem.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/4/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation

struct StubChatItemRepresentation: ChatItemRepresentation {
    init(_ item: Any?, chatGroupID chat: String?) {
        guid = NSString.stringGUID()
        fromMe = false
        time = 0
        if let obj = item as? AnyObject {
            className = NSStringFromClass(type(of: obj))
        } else {
            className = String(describing: item)
        }
    }
    
    var guid: String?
    var chatGroupID: String?
    var fromMe: Bool?
    var time: Double?
    var className: String
}
