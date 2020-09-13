//
//  DebugAPI.swift
//  imessage-rest
//
//  Created by Eric Rabil on 8/12/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import Vapor
import IMCore

private struct HealthStruct: Content {
    var chatsLoaded: Int;
    var messagesLoaded: Int;
    var contactsLoaded: Int;
    var socketsConnected: Int;
    var attachmentsLoaded: Int;
}

/// Debug API
public func bindDebugAPI(_ app: Application) {
    let debug = app.grouped("debug")
    
    debug.get("health") { req -> HealthStruct in
        HealthStruct(chatsLoaded: IMChatRegistry.shared.allExistingChats.count, messagesLoaded: IMChatRegistry.shared.allExistingChats.reduce(into: 0) { (result, chat) in
            result += chat._items.count
        }, contactsLoaded: 0, socketsConnected: StreamingAPI.shared.sockets.count, attachmentsLoaded: IMFileTransferCenter.sharedInstance()?.transfers?.count ?? 0)
    }
    
    debug.get("purge") { req -> HTTPStatus in
        if let transfers = IMFileTransferCenter.sharedInstance()?.value(forKey: "_guidToTransferMap") as? NSMutableDictionary {
            transfers.removeAllObjects()
        }
        
        return .noContent
    }
}
