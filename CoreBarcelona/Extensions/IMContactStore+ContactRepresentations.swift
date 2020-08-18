//
//  IMContactStore+ContactRepresentations.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/9/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

extension IMContactStore {
    static var shared: IMContactStore {
        IMContactStore.sharedInstance()!
    }
    
    var allContacts: [CNContact] {
        contactStore.contacts()
    }
    
    /**
     Helper function for searching the contact store
     */
    func representations(matching search: String? = nil, limit: Int? = nil) -> BulkContactRepresentation {
        var registry: [String: ContactRepresentation] = [:]
        var strangers: [HandleRepresentation] = []
        
        let includeStrangers = search == nil && limit == nil
        
        let registrar = IMHandleRegistrar.sharedInstance()!
        
        // MARK: - Map handles to contacts
        registrar.allIMHandles()!.forEach { handle in
            let representation = HandleRepresentation(handle)
            
            if let contact = IMContactStore.shared.fetchCNContact(forHandleID: handle.id, withKeys: CNContactStore.defaultKeysToFetch) as? CNContact {
                let representation = ContactRepresentation(contact)
                if !representation.empty {
                    registry[contact.identifier] = representation
                }
            }
            
            guard let contactID = handle.cnContact?.identifier, var contact = registry[contactID] else {
                if includeStrangers {
                    strangers.append(representation)
                }
                return
            }
            
            contact.addHandle(representation)
            
            registry[contactID] = contact
        }
        
        var contacts = Array(registry.values)
        contacts.sort()
        
        return BulkContactRepresentation(contacts: contacts, strangers: strangers)
    }
}
