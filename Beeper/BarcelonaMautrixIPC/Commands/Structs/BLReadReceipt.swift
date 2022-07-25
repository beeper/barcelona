//
//  BLReadReceipt.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 5/24/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation

public struct BLReadReceipt: Codable, ChatResolvable {
    public var sender_guid: String?
    public var is_from_me: Bool
    public var chat_guid: String
    public var read_up_to: String
    public var correlation_id: String?
    public var sender_correlation_id: String?
}
