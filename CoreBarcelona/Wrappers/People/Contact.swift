//
//  Contact.swift
//  imessage-rest
//
//  Created by Eric Rabil on 8/12/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import Contacts
import IMCore

struct ContactIDRepresentation: Codable {
    var id: String
}

struct BulkContactRepresentation: Codable {
    var contacts: [Contact]
    var strangers: [Handle]
}

struct Contact: Codable, Comparable {
    static func < (lhs: Contact, rhs: Contact) -> Bool {
        guard let lhsFullName = lhs.fullName else { return false }
        guard let rhsFullName = rhs.fullName else { return true }
        return lhsFullName < rhsFullName
    }
    
    static func == (lhs: Contact, rhs: Contact) -> Bool {
        return lhs.id == rhs.id
    }
    
    init(_ person: IMPerson) {
        self.id = person.cnContactID
        self.firstName = person.firstName
        self.middleName = nil
        self.lastName = person.lastName
        self.fullName = person.fullName
        self.nickname = person.nickname
        self.hasPicture = person.imageDataWithoutLoading != nil
        
        self.handles = [person.phoneNumbers, person.allEmails].flatMap {
            $0.compactMap {
                guard let id = $0 as? String else {
                    print("wtf \($0)")
                    return nil
                }
                
                return Handle(id: id, isBusiness: false)
            }
        }
    }
    
    init(_ contact: CNContact) {
        self.id = contact.identifier
        self.firstName = contact.givenName.count == 0 ? nil : contact.givenName
        self.middleName = contact.middleName.count == 0 ? nil : contact.middleName
        self.lastName = contact.familyName.count == 0 ? nil : contact.familyName
        self.fullName = CNContactFormatter.string(from: contact, style: .fullName)
        self.nickname = contact.nickname.count == 0 ? nil : contact.nickname
        self.hasPicture = contact.thumbnailImageData != nil
        
        self.handles = contact.phoneNumbers.reduce(into: contact.emailAddresses.reduce(into: []) { (result, email) in
            result.append(Handle(id: email.value as String, isBusiness: false))
        }) { (result, phoneNumber) in
            guard let countryCode = phoneNumber.value.value(forKey: "countryCode") as? String, let phoneNumber = phoneNumber.value.value(forKey: "digits") as? String else {
                return
            }
            guard let normalized = IMNormalizedPhoneNumberForPhoneNumber(phoneNumber, countryCode, true) else {
                return
            }
            result.append(Handle(id: "+\(normalized)", isBusiness: false))
        }
    }
    
    var id: String
    var firstName: String?
    var middleName: String?
    var lastName: String?
    var fullName: String?
    var nickname: String?
    var countryCode: String?
    var hasPicture: Bool
    var handles: [Handle]
    
    var empty: Bool {
        return (self.firstName?.count ?? 0) == 0 && (self.middleName?.count ?? 0) == 0 && (self.lastName?.count ?? 0 == 0) && (self.nickname?.count ?? 0) == 0 && self.hasPicture == false
    }
    
    mutating func addHandle(_ handle: Handle) {
        if handles.contains(handle) {
            return
        }
        handles.append(handle)
    }
}
