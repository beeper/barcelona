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

private func ensuredPrefix(_ handleID: String, withService service: String) -> String {
    if handleID.split(separator: ";").count == 3 {
        return handleID
    } else {
        return service + ";-;" + (handleID.split(separator: ";").last ?? handleID[...])
    }
}

public struct BLContact: Codable {
    public init(first_name: String? = nil, last_name: String? = nil, nickname: String? = nil, avatar: String? = nil, phones: [String], emails: [String], user_guid: String, primary_identifier: String? = nil, serviceHint: String = "iMessage", correl_id: String? = nil) {
        self.first_name = first_name
        self.last_name = last_name
        self.nickname = nickname
        self.avatar = avatar
        self.phones = phones
        self.emails = emails
        self.user_guid = ensuredPrefix(user_guid, withService: serviceHint)
        self.primary_identifier = primary_identifier
        self.correl_id = correl_id
    }
    
    public init() {
        first_name = nil
        last_name = nil
        nickname = nil
        avatar = nil
        phones = []
        emails = []
        user_guid = ""
        primary_identifier = nil
        correl_id = nil
    }
    
    public var first_name: String?
    public var last_name: String?
    public var nickname: String?
    public var avatar: String?
    public var phones: [String]
    public var emails: [String]
    public var user_guid: String
    public var primary_identifier: String?
    public var correl_id: String?
//    public var contact_id: String
}

private extension BLContactSuggestionData {
    var imageData: String? {
        guard let image = image else {
            return nil
        }
        
        return try? Data(contentsOf: image).base64EncodedString()
    }
}

public extension BLContact {
    init(suggestion: BLContactSuggestionData, phoneHandles: [String], emailHandles: [String], handleID: String) {
        first_name = suggestion.firstName
        last_name = suggestion.lastName
        nickname = suggestion.displayName
        avatar = suggestion.imageData
        phones = phoneHandles
        emails = emailHandles
        user_guid = handleID
//        contact_id = suggestion.syntheticContactID
    }
}
