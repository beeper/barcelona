//
//  ContactResolvable.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 5/24/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import CoreBarcelona

public protocol ContactResolvable {
    var user_guid: String { get set }
}

public extension ContactResolvable {
    var contact: CNContact? {
        IMContactStore.shared.fetchCNContactForHandle(withID: user_guid)
    }
    
    var blContact: BLContact? {
        guard let contact = contact else {
            return nil
        }
        
        return contact.barcelonaContact.blContact(withGUID: user_guid, avatar: contact.thumbnailImage(size: 0)?.data.base64EncodedString())
    }
}
