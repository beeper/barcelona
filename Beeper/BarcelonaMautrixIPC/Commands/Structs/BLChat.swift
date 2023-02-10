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

@MainActor
public extension IMChat {
    var blChat: BLChat {
        BLChat(chat_guid: blChatGUID, title: displayName, members: participants.map(\.id), correlation_id: correlationIdentifier)
    }
}

public struct BLChat: Codable, ChatResolvable {
    public var chat_guid: String
    public var title: String?
    public var members: [String]
    public var correlation_id: String?
}
