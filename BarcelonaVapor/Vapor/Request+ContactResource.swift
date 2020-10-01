//
//  Request+ContactResource.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/11/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import CoreBarcelona
import Contacts
import Vapor

extension Request {
    var cnContact: CNContact! {
        get {
            storage[CNContactStorageKey]
        }
        set {
            storage[CNContactStorageKey] = newValue
        }
    }
    
    var contact: Contact! {
        guard let cnContact = cnContact else {
            return nil
        }
        
        return Contact(cnContact)
    }
}
