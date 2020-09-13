//
//  IMChatRegistry+LoadMessageWithGUID.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/5/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import NIO
import IMCore
import os.log

let log_IMChat = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "IMChat+MessageQueries")

let messageQuerySystem = MultiThreadedEventLoopGroup.init(numberOfThreads: 5)

/**
 Provides various functions to aid in the lazy resolution of messages
 */
extension IMChat {
    var chatItemRules: IMTranscriptChatItemRules {
        return self.value(forKey: "_chatItemRules") as! IMTranscriptChatItemRules
    }
}
