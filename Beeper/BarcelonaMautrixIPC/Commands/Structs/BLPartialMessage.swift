//
//  BLPartialMessage.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 5/24/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import Barcelona
import BarcelonaMautrixIPCProtobuf

public typealias BLPartialMessage = PBSendResponse

public extension Message {
    var partialMessage: BLPartialMessage {
        .with {
            $0.guid = id
            $0.service = service.rawValue
            $0.time = .init(timeIntervalSince1970: time)
        }
    }
}
