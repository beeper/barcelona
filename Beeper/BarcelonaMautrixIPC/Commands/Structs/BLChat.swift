//
//  BLChat.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 5/24/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import Barcelona
import IMCore

public extension IMChat {
    var blChat: BLChat {
        BLChat(chat_guid: blChatGUID, title: displayName, members: participants.map(\.id), correl_id: CBSenderCorrelationController.shared.correlate(self))
    }
}

public extension Chat {
    var blChat: BLChat {
        BLChat(chat_guid: blChatGUID, title: displayName, members: participants, correl_id: CBSenderCorrelationController.shared.correlate(self))
    }
}

public struct BLChat: Codable, ChatResolvable {
    public var chat_guid: String
    public var title: String?
    public var members: [String]
    public var correl_id: String?
}
