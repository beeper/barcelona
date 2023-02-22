//
//  BLTypingNotification.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 5/24/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation

public struct BLTypingNotification: Codable, ChatResolvable {
    public var chat_guid: String
    public var typing: Bool
}
