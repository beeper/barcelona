//
//  ChatResolvable.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 5/24/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import CoreBarcelona

public protocol ChatResolvable {
    var chat_guid: String { get set }
}

public extension ChatResolvable {
    var chat: IMChat? {
        IMChatRegistry.shared.existingChat(withGUID: chat_guid)
    }
}
