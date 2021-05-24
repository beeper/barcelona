//
//  BLContact.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 5/24/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation

public struct BLContact: Codable {
    public var first_name: String?
    public var last_name: String?
    public var nickname: String?
    public var avatar: String?
    public var phones: [String]
    public var emails: [String]
    public var user_guid: String
    public var contact_id: String
}
