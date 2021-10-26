//
//  BLMessageStatus.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 5/24/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation

public struct BLMessageStatus: Codable {
    public var guid: String
    public var status: String
}
