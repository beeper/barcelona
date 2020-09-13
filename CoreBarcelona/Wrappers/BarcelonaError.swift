//
//  MessagesError.swift
//  imessage-rest
//
//  Created by Eric Rabil on 8/15/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation

struct BarcelonaError: Error {
    var code: Int
    var message: String
}
