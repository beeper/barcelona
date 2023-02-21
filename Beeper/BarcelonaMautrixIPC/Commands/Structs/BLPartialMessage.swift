//
//  BLPartialMessage.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 5/24/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Barcelona
import Foundation

public struct BLPartialMessage: Codable {
    public var guid: String
    public var service: String
    public var timestamp: Double
}

extension Message {
    public var partialMessage: BLPartialMessage {
        BLPartialMessage(guid: id, service: service.rawValue, timestamp: time)
    }
}
