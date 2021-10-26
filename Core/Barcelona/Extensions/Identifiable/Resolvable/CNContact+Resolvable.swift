//
//  CNContact+Resolvable.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/11/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import Contacts
import IMCore
import os.log

extension CNContact: Resolvable, _ConcreteBasicResolvable {
    public static func resolve(withIdentifiers identifiers: [String]) -> [CNContact] {
        let store = IMContactStore.sharedInstance()!.contactStore!
        
        do {
            return try identifiers.map {
                try store.unifiedContact(withIdentifier: $0, keysToFetch: CNContactStore.defaultKeysToFetch)
            }
        } catch {
            os_log("Failed to load contacts with identifiers %{private}@ with error %@", type: .error, identifiers, error.localizedDescription)
            
            return []
        }
    }
}
