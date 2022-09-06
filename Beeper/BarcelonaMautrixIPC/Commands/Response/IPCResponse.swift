//
//  IPCResponse.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 6/1/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import Swog

public extension IPCPayload {
    func respond(_ response: IPCResponse) {
        self.reply(withCommand: response)
    }
}

public typealias IPCResponse = IPCCommand