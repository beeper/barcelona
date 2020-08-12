//
//  CNContactStore+AllContacts.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/8/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import Contacts

extension CNContactStore {
    static var defaultKeysToFetch: [CNKeyDescriptor] {
        [
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
            CNContactEmailAddressesKey as NSString,
            CNContactPhoneNumbersKey as NSString,
            CNContactImageDataAvailableKey as NSString,
            CNContactThumbnailImageDataKey as NSString
        ]
    }
    
    func contacts(matching string: String? = nil, limit: Int? = nil) -> [CNContact] {
        let keysToFetch: [CNKeyDescriptor] = CNContactStore.defaultKeysToFetch
        
        var results: [CNContact] = []
        
        let fetchRequest = CNContactFetchRequest(keysToFetch: keysToFetch)
        
        if let match = string {
            fetchRequest.predicate = CNContact.predicateForContacts(matchingName: match)
        }
        
        do {
            try self.enumerateContacts(with: fetchRequest) { (contact, stop) in
                results.append(contact)
                if let limit = limit, results.count >= limit {
                    stop.pointee = true
                }
            }
        } catch {
            print("failed to enumerate contacts! \(error)")
        }
        
        return results
    }
}
