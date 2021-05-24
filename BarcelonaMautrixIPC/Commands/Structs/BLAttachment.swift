//
//  BLAttachment.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 5/24/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation

public struct BLAttachment: Codable {
    public var mime_type: String?
    public var file_name: String
    public var path_on_disk: String
}
