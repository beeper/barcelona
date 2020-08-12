//
//  IMChat+Acknowledgment.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/5/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import Vapor

extension IMChat {
    /**
     Sends a tapback for a given message, calling back with a Vapor abort if the operation fails
     */
    func tapback(message: IMMessage, index: Int, type: Int, overridingItemType: UInt8?, _ callback: (Abort?) -> ()) {
        guard let subpart = message.subpart(at: index) else { return callback(Abort(.notFound)) }
        
        sendMessageAcknowledgment(Int64(type), forChatItem: subpart, withMessageSummaryInfo: subpart.summaryInfo(for: message, in: self, itemTypeOverride: overridingItemType))
        
        callback(nil)
    }
    
    /**
     Sends a tapback for a given message, calling back with a Vapor abort if the operation fails
     */
    func tapback(guid: String, index: Int, type: Int, overridingItemType: UInt8?, _ callback: @escaping (Abort?) -> ()) {
        loadMessage(withGUID: guid) { message in
            guard let message = message else { return callback(Abort(.notFound)) }
            self.tapback(message: message, index: index, type: type, overridingItemType: overridingItemType, callback)
        }
    }
    
    func associatedMessageItemsForMessage(guid: String) -> [IMAssociatedMessageItem] {
//        print(IMDaemonController.sharedInstance()!.messages(withAssociatedGUID: guid))
//        IMDaemonController.sharedInstance()!._populateParentMessagesIfNeeded(<#T##arg1: Any!##Any!#>)
        
        return []
    }
}
