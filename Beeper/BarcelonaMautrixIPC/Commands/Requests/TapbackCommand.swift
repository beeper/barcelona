//
//  TapbackCommand.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 5/24/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import Barcelona

public struct TapbackCommand: Codable, ChatResolvable, TargetResolvable {
    public var chat_guid: String
    public var target_guid: String
    public var type: Int
    public var metadata: Message.Metadata?
}

public extension TapbackCommand {
    var creation: TapbackCreation? {
        return TapbackCreation(item: target_guid, message: target_guid, type: type)
    }
}
