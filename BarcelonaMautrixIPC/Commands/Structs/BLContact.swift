//
//  BLContact.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 5/24/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import Contacts
import Barcelona

public extension CNContact {
    var barcelonaContact: Contact {
        Contact(self)
    }
}

public extension Contact {
    func blContact(withGUID guid: String, avatar: String? = nil) -> BLContact {
        BLContact(first_name: firstName, last_name: lastName, nickname: nickname, avatar: avatar, phones: phoneNumbers, emails: emailAddresses, user_guid: guid, contact_id: id)
    }
    
    var phoneNumbers: [String] {
        handles.filter {
            $0.format == .phoneNumber
        }.map(\.id)
    }
    
    var emailAddresses: [String] {
        handles.filter {
            $0.format == .email
        }.map(\.id)
    }
}

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
