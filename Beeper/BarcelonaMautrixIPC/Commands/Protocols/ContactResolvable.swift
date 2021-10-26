//
//  ContactResolvable.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 5/24/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import Barcelona
import Contacts
import IMCore

public protocol ContactResolvable {
    var user_guid: String { get set }
}

public extension ContactResolvable {
    var contact: CNContact? {
        IMContactStore.shared.fetchCNContactForHandle(withID: user_guid)
    }
    
    var normalizedHandleID: String {
        guard user_guid.contains(";"), let last = user_guid.split(separator: ";").last else {
            return user_guid
        }
        
        return String(last)
    }
    
    var contactSuggestion: BLContactSuggestionData? {
        BLResolveContactSuggestionData(forHandleID: normalizedHandleID)
    }
    
    var blContactFromCNContact: BLContact? {
        guard let contact = contact else {
            return nil
        }
        
        return contact.barcelonaContact.blContact(withGUID: user_guid, avatar: contact.thumbnailImage(size: 0)?.data.base64EncodedString())
    }
    
    var blContactFromSuggestionData: BLContact? {
        guard let suggestion = contactSuggestion else {
            return nil
        }
        
        let phones = user_guid.isPhoneNumber ? [user_guid] : []
        let emails = user_guid.isEmail ? [user_guid] : []
        
        return BLContact(suggestion: suggestion, phoneHandles: phones, emailHandles: emails, handleID: user_guid)
    }
    
    var blContact: BLContact? {
        blContactFromCNContact ?? blContactFromSuggestionData
    }
}
