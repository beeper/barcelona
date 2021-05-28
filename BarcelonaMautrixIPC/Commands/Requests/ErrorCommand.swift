//
//  ErrorCommand.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 5/25/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation

public struct ErrorCommand: Codable {
    public var code: String
    public var message: String
}
