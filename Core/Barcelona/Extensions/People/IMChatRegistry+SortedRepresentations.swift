//
//  IMChatRegistry+SortedRepresentations.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/9/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

extension IMChatRegistry {
    public static var shared: IMChatRegistry {
        IMChatRegistry.sharedInstance()!
    }

    public var allChats: [IMChat] {
        if BLIsSimulation {
            return simulatedChats as! [IMChat]
        } else {
            return allExistingChats ?? []
        }
    }

    /**
     Returns all chats sorted by their last update, with a limit if requested
     */
    public func allSortedChats(limit: Int? = nil, after: String? = nil) -> [Chat] {
        var chats = allChats.sorted { (chat1, chat2) in
            let time1 =
                chat1.lastMessage?.time ?? NSDate.__im_dateWithNanosecondTimeInterval(
                    sinceReferenceDate: chat1.lastMessageTimeStampOnLoad
                )!
            let time2 =
                chat2.lastMessage?.time ?? NSDate.__im_dateWithNanosecondTimeInterval(
                    sinceReferenceDate: chat2.lastMessageTimeStampOnLoad
                )!

            return time1 > time2
        }

        if let limit = limit {
            chats = Array(chats.prefix(limit))
        }

        return chats.map(Chat.init)
    }
}
