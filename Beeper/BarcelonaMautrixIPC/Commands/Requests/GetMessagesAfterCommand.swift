//
//  GetMessagesAfterCommand.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 5/24/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation

public struct GetMessagesAfterCommand: Codable, ChatResolvable {
    public var chat_guid: String
    public var timestamp: Double
    public var limit: Int?

    public var date: Date {
        Date(timeIntervalSince1970: timestamp)
    }
}
