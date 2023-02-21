//
//  MessagesError.swift
//  imessage-rest
//
//  Created by Eric Rabil on 8/15/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation

public struct BarcelonaError: Error {
    public init(code: Int, message: String) {
        self.code = code
        self.message = message
    }

    public var code: Int
    public var message: String
}
