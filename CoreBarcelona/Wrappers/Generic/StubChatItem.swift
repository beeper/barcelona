//
//  PhantomChatItem.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/4/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import Vapor

struct StubChatItemRepresentation: ChatItemRepresentation, Content {
    init(_ item: NSObject, chatGroupID chat: String?) {
        guid = NSString.stringGUID()
        fromMe = false
        time = 0
        className = NSStringFromClass(type(of: item))
    }
    
    var guid: String?
    var chatGroupID: String?
    var fromMe: Bool?
    var time: Double?
    var className: String
}
