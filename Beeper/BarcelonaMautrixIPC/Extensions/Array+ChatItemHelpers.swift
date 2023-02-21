//
//  Array+ChatItemHelpers.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 8/23/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Barcelona
import Foundation

extension Collection where Element == ChatItem {
    var messages: [Message] {
        compactMap {
            $0 as? Message
        }
    }

    var blMessages: [BLMessage] {
        var messages = messages.map(BLMessage.init(message:))

        messages.sort(by: <)

        return messages
    }
}
